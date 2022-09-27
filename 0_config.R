
p0_targets_list <- list(
  
  # initial vars
  tar_target(pO_selected_crs, 5070),
  tar_target(pO_states_dwnld_url, 'https://prd-tnm.s3.amazonaws.com/StagedProducts/Small-scale/data/Boundaries/statesp010g.shp_nt00938.tar.gz'),
  
  # Date range
  tar_target(p0_start, "2000-01-01"),
  tar_target(p0_end, "2020-01-01"),
  
  # HUC Codes

  # NWIS Parameter Codes
  
  ## SW: discharge : 00060 + stream stage: 00072
  tar_target(p0_sw_params, c('00060','00065')),
  ## GW: water depth, water altitude, tritium, C-13 / C-14, similar chem constituents as listed at left
  tar_target(p0_gw_params, c('72019'))
  
)
