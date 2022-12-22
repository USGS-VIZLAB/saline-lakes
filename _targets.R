library(targets)

options(tidyverse.quiet = TRUE, timeout = 500)
tar_option_set(packages = c("tidyverse","sbtools","sf",'dataRetrieval',"nhdplusTools",'dplyr','readxl','readr','stringr','mapview',
                            'leaflet', 'httr', 'scico', 'openxlsx','rmapshaper', 'scales', 'retry','tryCatchLog', 'ggplot2', 'snakecase'))

## Sourcing files
source('0_config.R')

source("1_fetch_spatial.R")
source('1_build_raw_feedback_xlsx.R')
source("1_fetch_nwis.R")

source("2_process_lakes_tribs.R")
source("2_process_watershed_boundary.R")
source('2_process_sw_gw_site_data.R')

source("3_viz_prep.R")
source("3_visualize.R")

source('4_outputs.R')

## create dirs in `in` folder
dir.create('1_fetch/in/nhdhr', showWarnings = FALSE)
dir.create('1_fetch/in/states_shp', showWarnings = FALSE)

# Return the complete list of targets
c(p0_targets_list,
  p1_sp_targets_list, p1_feeback_xlsx_targets_list, p1_nw_targets_list,
  p2_watershed_boundary_targets_list, p2_lakes_tribs_targets_list, p2_sw_gw_site_targets_list,
  p3_prep_viz_targets_list, p3_viz_targets_list,
  p4_output_targets_list
  )