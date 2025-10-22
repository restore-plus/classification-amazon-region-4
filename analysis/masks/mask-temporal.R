library(sits)
library(restoreutils)

#
# General definitions
#

# Local directories
base_masks_dir <- restoreutils::project_masks_dir()

# Mask - version
mask_version <- "rules-latest"

# Hardware - Multicores
multicores <- 40

# Hardware - Memory size
memsize <- 180

#
# 1. Generate directories
#
output_dir <- create_data_dir(base_masks_dir / mask_version, "temporal-allyears")


#
# 2. Get masks files
#
files <- restoreutils::get_restore_rds_files(mask_version)

#
# 3. Apply water consistency rule
#

# Define output dir
water_year <- 2019
water_output_dir <- base_masks_dir / water_year
water_version < - "temporal-mask-1"

# Define years to apply
water_mask_years <- c(2018, 2019, 2020)

# Filter years to apply 
files_water <- files[files[["year"]] %in% water_mask_years,]

# Reclassify water 
water_outfile <- restoreutils::reclassify_rule24_temporal_water_consistency(
    files          = files_water,
    water_class_id = 3,
    year           = water_year,
    version        = water_version,
    multicores     = multicores,
    memsize        = memsize,
    output_dir     = water_output_dir
)

# Update water file
files[files[["year"]] == water_year,] <- water_outfile

#
# 4. Apply perene mask
#

# Define years to apply
perene_mask_years <- c(2009, 2011, 2013, 2019, 2021)
perene_version <- "temporal-mask-2"

# Apply perene rules
perene_outfiles <- sapply(perene_mask_years, function(year) {
    # Define output dir
    perene_output_dir <- base_masks_dir / year
    
    # Load after terraclass
    tc_after <- get(paste0("load_terraclass_", year + 1))
    tc_after <- tc_after(multicores = multicores, memsize = memsize)
    tc_after <- tc_after[["file_info"]][[1]][["path"]]
    
    # Load before terraclass
    tc_before <- get(paste0("load_terraclass_", year - 1))
    tc_before <- tc_before(multicores = multicores, memsize = memsize)
    tc_before <- tc_before[["file_info"]][[1]][["path"]]
    
    # Filter current year
    year_file <- files[files[["year"]] == year, "path"]
    
    # Filter label value
    class_value <- files[files[["year"]] == year, "label"][[1]]["Perene"]

    restoreutils::reclassify_rule27_temporal_trajectory_perene_mask(
        files                = year_file,
        files_mask           = c(tc_before, tc_after),
        year                 = year,
        perene_class_id      = class_value,
        perene_mask_class_id = 12,
        version              = perene_version,
        multicores           = multicores,
        memsize              = memsize,
        output_dir           = output_dir
    )
})

# Update perene files
files[files[["year"]] == perene_mask_years,] <- perene_outfiles

#
# 5. Reclassify agriculture neighbor 
#

# Definitions
agri_version <- "temporal-mask-3"

# Arrange files
files <- dplyr::arrange(files, .data[["year"]])

# Apply agriculture temporal rule 
file_brick <- restoreutils::reclassify_rule22_temporal_annual_agriculture(
    files                       = files[["path"]],
    annual_agriculture_class_id = 2,
    version                     = agri_version,
    multicores                  = multicores,
    memsize                     = memsize,
    output_dir                  = output_dir
)

agri_files <- restoreutils::reclassify_temporal_results_to_maps(
    years = files[["year"]], 
    output_dir = output_dir, 
    file_brick = file_brick, 
    agri_version = agri_version
)