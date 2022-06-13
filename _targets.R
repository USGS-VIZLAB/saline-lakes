library(targets)

options(tidyverse.quiet = TRUE)
tar_option_set(packages = c("tidyverse","sbtools","sf","nhdplusTools"))

source("1_fetch.R")
source("2_process.R")

## CRS: keeping crs at 4326 for now
selected_crs = 4326

## states pull
  



# Return the complete list of targets
c(p1_targets_list)