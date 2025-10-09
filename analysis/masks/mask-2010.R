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
mask_version <- "v3"

# Classification - version
classification_version <- "samples-v1-2010-eco4"

# Classification - years
classification_year <- 2010

# Hardware - Multicores
multicores <- 35

# Hardware - Memory size
memsize    <- 100

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
prodes <- load_prodes_2010(multicores = multicores, memsize = memsize)

# Terraclass
terraclass_2022 <- load_terraclass_2022(multicores = multicores, memsize = memsize)

# Terraclass
terraclass_2010 <- load_terraclass_2010(multicores = multicores, memsize = memsize)

#
# 3. Load classification
#
eco4_class <- load_restore_map_glad(
  data_dir   = classification_dir,
  multicores = multicores,
  memsize    = memsize,
  version    = classification_version,
  tiles      = "MOSAIC"
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
  version      = "step1"
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
  version    = "step2"
)

# Rule 2
eco4_mask <- restoreutils::reclassify_rule2_current_deforestation(
  cube       = eco4_mask,
  mask       = prodes,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step3",
  rarg_year  = classification_year # <- rule argument: Deforestation year
)

# Rule 3
eco4_mask <- restoreutils::reclassify_rule3_pasture_wetland(
  cube       = eco4_mask,
  mask       = prodes,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step4",
  rarg_year  = classification_year # <- rule argument: Deforestation year
)

# Rule 4
eco4_mask <- restoreutils::reclassify_rule4_silviculture(
  cube       = eco4_mask,
  mask       = terraclass_2010,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step5"
)

# Rule 5
eco4_mask <- restoreutils::reclassify_rule5_silviculture_pasture(
  cube       = eco4_mask,
  mask       = terraclass_2010,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step6"
)

# Rule 6
eco4_mask <- restoreutils::reclassify_rule6_semiperennial(
  cube       = eco4_mask,
  mask       = terraclass_2010,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step7"
)

# Rule 7
eco4_mask <- restoreutils::reclassify_rule17_semiperennial_glad(
  cube       = eco4_mask,
  mask       = terraclass_2010,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step8"
)

# Rule 8
eco4_mask <- restoreutils::reclassify_rule18_annual_agriculture_glad(
  cube       = eco4_mask,
  mask       = terraclass_2010,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step9"
)

# Rule 9
eco4_mask <- restoreutils::reclassify_rule8_annual_agriculture_v2(
  cube       = eco4_mask,
  mask       = terraclass_2010,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step10"
)

# Rule 10
eco4_mask <- restoreutils::reclassify_rule23_pasture_deforestation_in_nonforest(
  cube       = eco4_mask,
  mask       = prodes,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step11"
)

# Rule 11
eco4_mask <- restoreutils::reclassify_rule9_minning(
  cube       = eco4_mask,
  mask       = terraclass_2010,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step12"
)

# Rule 12
eco4_mask <- restoreutils::reclassify_rule10_urban_area(
  cube           = eco4_mask,
  mask           = terraclass_2010,
  multicores     = multicores,
  memsize        = memsize,
  output_dir     = output_dir,
  version        = "step13"
)

# Rule 13
eco4_mask <- restoreutils::reclassify_rule21_pasture_annual_agriculture(
  cube           = eco4_mask,
  mask           = terraclass_2010,
  multicores     = multicores,
  memsize        = memsize,
  output_dir     = output_dir,
  rarg_year      = classification_year,
  version        = "step14"
)

# Rule 14
eco4_mask <- restoreutils::reclassify_rule12_non_forest(
  cube       = eco4_mask,
  mask       = prodes,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step15"
)

# Rule 15
eco4_mask <- restoreutils::contextual_cleaner(
  cube         = eco4_mask,
  window_size  = 5L,
  target_class = as.numeric(names(sits_labels(eco4_mask)[sits_labels(eco4_mask) == "2ciclos"])),
  mode_class   = as.numeric(names(sits_labels(eco4_mask)[sits_labels(eco4_mask) == "area_urbanizada"])),
  multicores   = multicores,
  memsize      = memsize,
  output_dir   = output_dir,
  version      = "step16"
)

# Rule 16
eco4_mask <- restoreutils::reclassify_rule19_perene(
  cube       = eco4_mask,
  mask       = terraclass_2010,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  rarg_year  = classification_year,
  version    = "step17"
)

# Rule 17
eco4_mask <- restoreutils::reclassify_rule16_water_glad(
  cube       = eco4_mask,
  mask       = terraclass_2010,
  multicores = multicores,
  memsize    = memsize,
  output_dir = output_dir,
  version    = "step18"
)

# Crop
eco4_mask <- sits_mosaic(
  cube       = eco4_mask,
  crs        = restoreutils::crs_bdc(),
  roi        = eco_region_roi,
  multicores = multicores,
  output_dir = output_dir,
  version    = "step19"
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