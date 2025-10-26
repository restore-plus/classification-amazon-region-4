  
#
# Global configuration
#

# Define roi file
roi_file <- base::system.file("extdata/amazon/prodes-parallel-44.gpkg", package = "restoreutils")
# Define memory size
memsize <- 120
# Define multicores
multicores <- 75

#
# Classifications crop
#

# Define years to crop
class_years_to_crop <- 2000:2022
# Base classification dir
class_base_dir <- restoreutils::project_classifications_dir()
# Crop classification output
class_output_dir <- fs::path("data/derived/parallel-44-class")

purrr::map(class_years_to_crop, function(year) {
    # Define version
    classification_version <- "samples-v2-noperene-eco4"
    if (year < 2015) {
        classification_version <- "samples-v1-2010-eco4"
    }
    # Define output dir
    class_output_dir <- class_output_dir / classification_version / year
    restoreutils::classification_crop(
        year       = year, 
        roi_file   = roi_file, 
        multicores = multicores, 
        memsize    = memsize, 
        output_dir = class_output_dir,
        version    = classification_version
    )
})

tc_years_to_crop <- c(2008, 2010, 2012, 2014, 2018, 2020, 2022)

tc_version <- "tc-parallel-44"
tc_output_dir <- restoreutils::project_masks_dir()
purrr::map(tc_years_to_crop, function(year) {
    out_dir <- tc_output_dir / "base" / "terraclass" / tc_version / year
    restoreutils::terraclass_crop(
        year       = year, 
        roi_file   = roi_file, 
        multicores = multicores, 
        memsize    = memsize, 
        output_dir = out_dir
    )
})