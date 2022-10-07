source('3_visualize/src/prep_viz_data.R')

p3_prep_viz_targets_list <- list(
  
  ## Add label col to HUC spatial file + simplify() for easier visualization
  tar_target(
    p3_lakes_huc6_sf,
    prep_huc_viz_sf(huc_sf = p1_lakes_huc6_sf,
                    selected_huc_col = 'HUC6')
  ),
  tar_target(
    p3_lakes_huc8_sf,
    prep_huc_viz_sf(huc_sf = p1_lakes_huc8_sf,
                    selected_huc_col = 'HUC8')
  ),
  tar_target(
    p3_lakes_huc10_sf,
    prep_huc_viz_sf(huc_sf = p1_lakes_huc10_sf,
                    selected_huc_col = 'HUC10')
  ),
  
  ## Clean Saline lakes sf and add labels
  tar_target(
    p3_saline_lakes_sf,
    p2_saline_lakes_sf %>%
      mutate(state = str_sub(lake_w_state, -2)) %>%
      mutate(label = str_c("Lake: ", str_sub(lake_w_state, 1, -3), " ", str_sub(lake_w_state, -2))) %>%
      st_as_sf() %>%
      st_transform(crs = p0_selected_crs)
  ),
   
  ## This takes a long time because rmapshaper::ms_simplify() is very slow for me when simplifying flowlines
  tar_target(
    p3_lake_tributaries,
    p2_lake_tributaries %>%
      rmapshaper::ms_simplify() %>%
      mutate(label = paste0("Stream: ",
                            ifelse(gnis_name == " ", "No GNIS name/ID",
                                   paste0(gnis_name, " (", gnis_id, ")")),
                            " <br> Stream order ", streamorde)) %>%
      st_as_sf() %>%
      st_transform(crs = p0_selected_crs)
  ),
  
  ## Cleaning + filtering sites sf target by unique daily value sites
  ## Note: dv sites are typically perm. gauges. Instantaneous & daily values are collected at the same 
  ## location, therefore we assume dv sites are also iv sites
  tar_target(
    p3_dv_sites_in_watershed,
    prep_gage_viz_sf(watershed_sf = p1_site_in_watersheds_sf,
                     nwis_sites_df = p1_nwis_dv_sw_data,
                     selected_service = 'dv')
  ),
  
  ## Cleaning + filtering sites sf target by unique field measurement sites
  ## Note: field meas sites are more random and not always taken at permanent gauges
  tar_target(
    p3_fieldmeas_sites_in_watershed,
    prep_gage_viz_sf(watershed_sf = p1_site_in_watersheds_sf,
                     nwis_sites_df = p1_nwis_meas_sw_data,
                     selected_service = 'measurements')
  )
    
)
  


