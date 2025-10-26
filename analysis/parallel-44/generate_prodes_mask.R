#
# Global configuration
#
base::options(timeout = 1920)

#
# Auxiliary function
#
prepared_prodes_patched <- function(multicores) {
  # Define roi file
  roi_file <- base::system.file("extdata/amazon/prodes-parallel-44.gpkg", package = "restoreutils")

  prodes_dir <- "data/derived/masks/base/prodes/"
  prodes_amazonia <- restoreutils::download_prodes(
    year       = 2024,
    output_dir = prodes_dir,
    version    = "v2"
  )

  prodes_amazonia <- prodes_amazonia[prodes_amazonia["type"] == "raster", "file"][[1]]

  # Crop gdal
  sits:::.gdal_crop_image(
    file       = prodes_amazonia,
    out_file   = prodes_amazonia,
    roi_file   = roi_file,
    data_type  = "INT1U",
    as_crs     = "EPSG:4674",
    multicores = multicores,
    overwrite  = TRUE,
    miss_value = 255
  )

  # Return!
  prodes_amazonia
}


#
# General definitions
#
memsize    <- 300
multicores <- 75

version <- "v2"

years_to_mask <- c(2000:2024)


#
# 1) Prepare prodes
#
prepared_prodes_patched(multicores = multicores)


#
# 2) Generate forest mask
#
purrr::map(years_to_mask, function(mask_year) {
  restoreutils::prodes_generate_mask(
    target_year       = mask_year,
    version           = version,
    multicores        = multicores,
    memsize           = memsize,
    nonforest_mask    = TRUE,
    allow_forest_only = TRUE,
    prodes_loader     = restoreutils::load_prodes_2024
  )
})