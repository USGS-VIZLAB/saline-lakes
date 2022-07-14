library(targets)

options(tidyverse.quiet = TRUE, timeout = 300)
tar_option_set(packages = c("tidyverse","sbtools","sf",'dataRetrieval',"nhdplusTools",'dplyr','readxl','readr','stringr','mapview','leaflet', 'httr'))

source("1_fetch.R")
source("2_process.R")
source("3_visualize.R")

## create dirs in `in` folder
dir.create('1_fetch/in/nhdhr', showWarnings = FALSE)
dir.create('1_fetch/in/nhdhr_backup', showWarnings = FALSE)
#dir.create('1_fetch/in/states_shp', showWarnings = FALSE)

## CRS: keeping crs at 4326 for now
selected_crs <-  4326

states_download_url <- 'https://prd-tnm.s3.amazonaws.com/StagedProducts/Small-scale/data/Boundaries/statesp010g.shp_nt00938.tar.gz'



# Return the complete list of targets
c(p1_targets_list, p2_targets_list, p3_targets_list)