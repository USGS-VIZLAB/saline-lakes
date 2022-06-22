library(targets)

options(tidyverse.quiet = TRUE, timeout = 300)
tar_option_set(packages = c("tidyverse","sbtools","sf","nhdplusTools",'dplyr','readxl','readr','stringr'))

source("1_fetch.R")
source("2_process.R")

## create dirs in `in` folder
dir.create('1_fetch/in/nhdhr', showWarnings = FALSE)
dir.create('1_fetch/in/nhdhr_backup', showWarnings = FALSE)
#dir.create('1_fetch/in/states_shp', showWarnings = FALSE)

## CRS: keeping crs at 4326 for now
selected_crs <-  4326

# Return the complete list of targets
c(p1_targets_list)