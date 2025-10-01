set.seed(777)

library(sits)
library(restoreutils)

#
# General definitions
#
processing_context <- "eco 4"

# Local directories
base_masks_dir <- restoreutils::project_masks_dir()
base_classifications_dir <- restoreutils::project_classifications_dir()

# Mask - tiles (works as a roi)
mask_tiles <- c()

# Mask - version
mask_version <- "v2"

# Classification - version
classification_version <- "samples-v2-noperene-eco4"

# Classification - years
classification_year <- 2019

# Hardware - Multicores
multicores <- 35

# Hardware - Memory size
memsize <- 100

# ROI
eco_region_roi <- restoreutils::roi_ecoregions(
  region_id  = 4,
  crs        = restoreutils::crs_bdc(),
  as_union   = TRUE,
  use_buffer = TRUE
)

#
# 1. Define output directory
#
output_dir <- restoreutils::create_data_dir(
  base_masks_dir / mask_version, classification_year
)

classification_dir <- (
  base_classifications_dir / classification_version / classification_year
)


#
# 2. Load base masks
#

# PRODES data
prodes <- load_prodes_2019(multicores = multicores, memsize = memsize)

# Terraclass 2022
terraclass_2022 <- load_terraclass_2022(multicores = multicores, memsize = memsize)

# Terraclass
terraclass_2018 <- load_terraclass_2018(multicores = multicores, memsize = memsize)


#
# 3. Load classification
#
eco4_class <- load_restore_map_bdc(
  data_dir   = classification_dir,
  tiles      = "MOSAIC",
  multicores = multicores,
  memsize    = memsize,
  version    = classification_version
)


#
# 4. Clean data to reduce noise
#
eco4_class <- sits_clean(
  cube         = eco4_class,
  window_size  = 5,
  multicores   = multicores,
  memsize      = memsize,
  output_dir   = output_dir,
  version      = "mask-clean-step1",
  progress     = TRUE
)


#
# 5. Apply reclassification rules
#
# Rule 1
eco4_mask <- restoreutils::reclassify_rule1_secundary_vegetation(
  cube       = eco4_class,
  mask       = prodes,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step2"
)

# Rule 2
eco4_mask <- restoreutils::reclassify_rule2_current_deforestation(
  cube       = eco4_mask,
  mask       = prodes,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step3",
  rarg_year  = classification_year # <- rule argument: Deforestation year
)

# Rule 3
eco4_mask <- restoreutils::reclassify_rule3_pasture_wetland(
  cube       = eco4_mask,
  mask       = prodes,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step4",
  rarg_year  = classification_year # <- rule argument: Deforestation year
)

# Rule 4
eco4_mask <- restoreutils::reclassify_rule4_silviculture(
  cube       = eco4_mask,
  mask       = terraclass_2018,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step5"
)

# Rule 5
eco4_mask <- restoreutils::reclassify_rule5_silviculture_pasture(
  cube       = eco4_mask,
  mask       = terraclass_2018,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step6"
)

# Rule 6
eco4_mask <- restoreutils::reclassify_rule6_semiperennial(
  cube       = eco4_mask,
  mask       = terraclass_2018,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step7"
)

# Rule 7
eco4_mask <- restoreutils::reclassify_rule7_semiperennial_pasture(
  cube       = eco4_mask,
  mask       = terraclass_2018,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step8"
)

# Rule 8
eco4_mask <- restoreutils::reclassify_rule8_annual_agriculture(
  cube       = eco4_mask,
  mask       = terraclass_2018,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step9"
)

# Rule 9
eco4_mask <- restoreutils::reclassify_rule9_minning(
  cube       = eco4_mask,
  mask       = terraclass_2018,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step10"
)

# Rule 10
eco4_mask <- restoreutils::reclassify_rule10_urban_area(
  cube       = eco4_mask,
  mask       = terraclass_2018,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step11"
)

# Rule 11
eco4_mask <- restoreutils::reclassify_rule11_water(
  cube       = eco4_mask,
  mask       = terraclass_2018,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step12"
)

# Rule 12
eco4_mask <- restoreutils::reclassify_rule12_non_forest(
  cube       = eco4_mask,
  mask       = terraclass_2022,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "mask-prodes-step13"
)

eco4_mask <- sits_mosaic(
  cube       = eco4_mask,
  crs        = restoreutils::crs_bdc(),
  roi        = eco_region_roi,
  multicores = multicores,
  output_dir = output_dir,
  version    = "mask-prodes-step14"
)


#
# 6. Save cube object
#
saveRDS(eco4_mask, output_dir / "mask-cube.rds")


#
# 7. COG data
#
sf::gdal_addo(eco4_mask[["file_info"]][[1]][["path"]])


#
# Crop cube to tiles
#
if (length(mask_tiles)) {
  cube_files <- crop_to_roi(
    cube        = eco4_mask,
    tiles       = mask_tiles,
    multicores  = multicores,
    output_dir  = output_dir,
    grid_system = "BDC_MD_V2"
  )

  saveRDS(cube_files, output_dir / "mask-cube-tiles.rds")
}
