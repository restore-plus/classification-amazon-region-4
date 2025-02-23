set.seed(777)

library(sf)
library(fs)
library(sits)
library(dplyr)

#
# Cube definitions
#

# Cube dates
classification_years <- c(2021:2016)

# Cube directory
cube_base_dir <- get_cubes_dir()

#
# Hardware definitions
#

# Multicores
multicores <- 64

# Memory size
memsize <- 220


#
# 1. Generate indices
#
for (classification_year in classification_years) {
  #
  # 1.1. Define cube directory
  #
  cube_dir <- path(cube_base_dir) / classification_year

  #
  # 1.2. Load cube
  #
  cube <- sits_cube(
    source     = "HLS",
    collection = "HLSL30",
    data_dir   = cube_dir
  )

  #
  # 1.3. Generate NDVI
  #
  cube <- sits_apply(
    data       = cube,
    NDVI       = (`NIR-NARROW` - RED) / (`NIR-NARROW` + RED),
    output_dir = cube_dir,
    multicores = multicores,
    memsize    = memsize,
    progress   = TRUE
  )

  #
  # 1.4. Generate EVI (https://www.usgs.gov/landsat-missions/landsat-enhanced-vegetation-index)
  #
  cube <- sits_apply(
    data       = cube,
    EVI        = 2.5 * (( `NIR-NARROW` - RED ) / (`NIR-NARROW` + 6 * RED - 7.5 * BLUE + 1)),
    output_dir = cube_dir,
    multicores = multicores,
    memsize    = memsize,
    progress   = TRUE
  )

  #
  # 1.5. Generate MNDWI
  #
  cube <- sits_apply(
    data       = cube,
    MNDWI      = (GREEN - `SWIR-1`) / (GREEN + `SWIR-1`),
    output_dir = cube_dir,
    multicores = multicores,
    memsize    = memsize,
    progress   = TRUE
  )

  #
  # 1.6. Generate NBR (https://www.usgs.gov/landsat-missions/landsat-normalized-burn-ratio)
  #
  cube <- sits_apply(
    data       = cube,
    NBR        = ( `NIR-NARROW` - `SWIR-2` ) / ( `NIR-NARROW` + `SWIR-2` ),
    output_dir = cube_dir,
    multicores = multicores,
    memsize    = memsize,
    progress   = TRUE
  )
}
