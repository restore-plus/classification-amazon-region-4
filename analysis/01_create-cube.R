set.seed(777)

library(sf)
library(fs)
library(sits)
library(dplyr)
library(classificationamazonregion4)

#
# Authentication
#
earthdatalogin::edl_netrc(
  username = "<username>",
  password = "<password>"
)

#
# Cube definitions
#

# Cube dates
cube_years <- c(2021:2016)

# Temporal composition
cube_temporal_composition <- "P3M"

# Bands - Landsat-8 (HLS)
cube_bands_landsat <- c(
  "BLUE", "GREEN",
  "RED", "NIR-NARROW", "SWIR-1", "SWIR-2",
  "CLOUD"
)

# Bands - Sentinel-2 (HLS)
cube_band_sentinel <- c(
  "BLUE", "GREEN", "RED",
  "RED-EDGE-1", "RED-EDGE-2", "RED-EDGE-3",
  "NIR-BROAD", "NIR-NARROW", "WATER-VAPOR",
  "SWIR-1", "SWIR-2", "CLOUD"
)

# Cube directory
cube_base_dir <- get_cubes_dir()

# Region
cube_region_file <- "data/raw/region/amazon-regions-bdc-md.gpkg"

# Tiles (Required as the service doesn't support large bbox search)
bdc_tiles_file <- "data/raw/tiles/BDC_MD_V2Polygon.shp"

#
# Hardware definitions
#

# Multicores
multicores <- 64

# Memory size
memsize    <- 220

#
# 1. Create cube directory
#
dir_create(cube_base_dir, recurse = TRUE)

#
# 2. Load region file
#
region <- st_read(cube_region_file)

#
# 3. Load tiles file
#
tiles <- st_read(bdc_tiles_file)

#
# 4. Filter region for region number 4
#
region <- filter(region, layer == "eco_4")

region <- st_union(st_convex_hull(region))

#
# 5. Get BDC Tiles
#
tiles <- st_transform(tiles, st_crs(region))
tiles <- st_intersection(tiles, region)

#
# 6. Generate cubes
#
for (cube_year in cube_years) {
  print(paste0("Processing: ", cube_year))

  #
  # 6.1. Define cube dates
  #
  start_date <- paste0(cube_year, "-01-01")
  end_date   <- paste0(cube_year, "-12-31")

  #
  # 6.2. Create a directory for the current year
  #
  cube_dir_year <- path(cube_base_dir) / cube_year

  dir_create(cube_dir_year, recurse = TRUE)

  #
  # 6.3. Create Landsat cube
  #
  cube_year_landsat <- purrr::map_dfr(1:nrow(tiles), function(idx) {
    #
    # 6.3.1. Simplify geometry
    #
    tile <- tiles[idx,]
    tile_region <- st_union(st_convex_hull(tile))

    #
    # 6.3.2. Load cube
    #
    tryCatch(
      sits_cube(
        source     = "HLS",
        collection = "HLSL30",
        roi        = tile_region,
        start_date = start_date,
        end_date   = end_date,
        bands      = cube_bands_landsat
      ),
      error = function(e) {
        return(NULL)
      }
    )
  })

  #
  # 6.4. Create Sentinel cube
  #
  cube_year_sentinel <- purrr::map_dfr(1:nrow(tiles), function(idx) {
    #
    # 6.4.1. Simplify geometry
    #
    tile <- tiles[idx,]
    tile_region <- st_union(st_convex_hull(tile))

    #
    # 6.4.2. Load cube
    #
    tryCatch(
      sits_cube(
        source     = "HLS",
        collection = "HLSS30",
        roi        = tile_region,
        start_date = start_date,
        end_date   = end_date,
        bands      = cube_band_sentinel
      ),
      error = function(e) {
        return(NULL)
      }
    )
  })

  #
  # 6.5. Clean data
  #
  class_landsat <- class(cube_year_landsat)
  class_sentinel <- class(cube_year_sentinel)

  # Merge Landsat data
  cube_year_landsat <- cube_year_landsat |>
    group_by(tile) |>
    summarise(
      source = first(source),
      collection = first(collection),
      satellite = first(satellite),
      sensor = first(sensor),
      xmin = first(xmin),
      xmax = first(xmax),
      ymin = first(ymin),
      ymax = first(ymax),
      crs = first(crs),
      file_info = list(bind_rows(file_info))
    )

  # Merge sentinel
  cube_year_sentinel <- cube_year_sentinel |>
    group_by(tile) |>
    summarise(
      source = first(source),
      collection = first(collection),
      satellite = first(satellite),
      sensor = first(sensor),
      xmin = first(xmin),
      xmax = first(xmax),
      ymin = first(ymin),
      ymax = first(ymax),
      crs = first(crs),
      file_info = list(bind_rows(file_info))
    )

  # Update classes
  class(cube_year_landsat) <- class_landsat
  class(cube_year_sentinel) <- class_sentinel

  #
  # 6.6. Merge
  #
  cube_year <- sits_merge(cube_year_landsat, cube_year_sentinel)

  #
  # 6.7. Regularize
  #
  reg_cube <- sits_regularize(
    cube        = cube_year,
    period      = cube_temporal_composition,
    res         = 30,
    multicores  = multicores,
    output_dir  = cube_dir_year,
    grid_system = "BDC_MD_V2"
  )
}
