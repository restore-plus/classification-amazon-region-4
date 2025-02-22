set.seed(777)

library(sf)
library(fs)
library(sits)
library(dplyr)
library(classificationamazonregion4)

#
# Cube definitions
#

# Cube dates
cube_years <- c(1996, 2021:2014)

# Temporal composition
cube_temporal_composition <- "P3M"

# Bands
cube_bands <- c("BLUE", "GREEN", "RED", "NIR08" , "SWIR16", "SWIR22", "CLOUD")

# Cube directory
cube_base_dir <- get_cubes_dir()

# Region
cube_region_file <- "data/raw/region/amazon-regions-bdc-md.gpkg"

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
fs::dir_create(cube_base_dir, recurse = TRUE)

#
# 2. Load region file
#
region <- st_read(cube_region_file)

#
# 3. Filter region for region number 4
#
region <- filter(region, layer == "eco_4")

region <- st_union(st_convex_hull(region))

#
# 4. Generate cubes
#
for (cube_year in cube_years) {
  print(paste0("Processing: ", cube_year))

  #
  # 3.1. Define cube dates
  #
  start_date <- paste0(cube_year, "-01-01")
  end_date   <- paste0(cube_year, "-12-31")

  #
  # 3.2. Create a directory for the current year
  #
  cube_dir_year <- path(cube_base_dir) / cube_year

  fs::dir_create(cube_dir_year, recurse = TRUE)

  #
  # 3.3. Load cube
  #
  cube_year <- sits_cube(
    source     = "MPC",
    collection = "LANDSAT-C2-L2",
    roi        = region,
    start_date = start_date,
    end_date   = end_date,
    bands      = cube_bands
  )

  #
  # 3.4. Regularize
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
