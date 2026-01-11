library(sits)
library(restoreutils)

#
# General definitions
#
memsize    <- 180
multicores <- 95

version <- "v2"

year_to_prepare <- 2024:2000

#
# 1 Generate forest mask
#
prepare_prodes(
    region_id          = 4,
    years              = year_to_prepare,
    version            = version,
    multicores         = multicores,
    memsize            = memsize,
    nonforest_mask     = TRUE,
    nonforest_complete = TRUE
)
