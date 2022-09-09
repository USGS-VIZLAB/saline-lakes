library(targets)

options(tidyverse.quiet = TRUE, timeout = 300)
tar_option_set(packages = c("tidyverse","sbtools","sf",'dataRetrieval',"nhdplusTools",'dplyr','readxl','readr','stringr','mapview',
                            'leaflet', 'httr', 'scico', 'openxlsx', 'rmapshaper', 'scales', 'retry','tryCatchLog'))

source('0_config.R')
source("1_fetch_spatial.R")
source("1_fetch_nwis.R")
source("2_process.R")
source("3_visualize.R")

## create dirs in `in` folder
dir.create('1_fetch/in/nhdhr', showWarnings = FALSE)
dir.create('1_fetch/in/states_shp', showWarnings = FALSE)

# Return the complete list of targets
c(p0_targets_list, p1_sp_targets_list, p1_nw_targets_list, p2_targets_list, p3_targets_list)