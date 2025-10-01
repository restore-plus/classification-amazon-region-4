library(sits)
library(restoreutils)

#
# Config: Connection timeout
#
options(timeout = max(600, getOption("timeout")))


#
# 1) Download Terraclass data
#
restoreutils::prepare_terraclass(
    years      = c(2010),
    region_id  = 4,
    multicores = 5
)
