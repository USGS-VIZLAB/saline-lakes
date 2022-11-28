
p0_targets_list <- list(
  
  # initial vars
  tar_target(p0_selected_crs, 4326),
  # tar_target(pO_selected_crs, 5070),
  tar_target(pO_states_dwnld_url, 'https://prd-tnm.s3.amazonaws.com/StagedProducts/Small-scale/data/Boundaries/statesp010g.shp_nt00938.tar.gz'),
  
  # Date Range
  tar_target(p0_start, "2000-01-01"),
  tar_target(p0_end, "2022-11-27"),
  
  # HUC Codes
  tar_target(
  p0_additional_GSL_huc8,
  c('16010202','16010203', '16010204')
  ),

  # NWIS Parameter Codes
  # List of request params from project members - Link - https://doimspp.sharepoint.com/:x:/r/sites/IIDDStaff/Shared%20Documents/Function%20-%20Data%20Pipelines/Data_Science_Practitioners_Mtgs/tasks/saline_lakes/List%20of%20water%20and%20QW%20parameters%20for%20WMA%20data%20pipeline.xlsx?d=w467e83a8b1db40c0a6132bf5e6da5ab3&csf=1&web=1&e=PG8mLm

  ## SW - 2 params
  ### Discharge: 00060 - 'Discharge, ft^3/sec' ;  Stream Stage: 00065 - 'gage height, ft'
  ### for stream stage - determined based on discussion with SME that gage height pcode best describes stream stage
  tar_target(p0_sw_params, c('00060','00065')),
  
  ## GW - 4 plus others 
  ## water depth: 72019 (depth to water level), 
  ## water altitude: 62610 - GW Level above NGD 1929, 72150 - GW level above local mn sea level
  ## tritium: 07000 - Tritium, water, unfiltered, picocuries per liter
  ## C-13 / C-14,
  tar_target(p0_gw_params, c('72019', '62610','72150','07000'))
  ## WQ: 
  #   tar_target(p0_wq_params, c('000000'))
)
