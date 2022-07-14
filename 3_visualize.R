source('3_visualize/src/prep_viz_data.R')


p3_targets_list <- list(

  ## Fetch and Process saline lakes via specifically built function that creates the final saline lakes shapefile 
  ## This fun not yet generalized, special handling of lakes included in fun
  ## NOTE - Change nhdhr_lakes_path param with either p1_download_nhdhr_lakes_path or p1_download_nhdhr_lakes_backup_path depending on where nhdhr lives
  
  tar_target(
    p3_saline_lakes_sf,
    prep_lakes_viz_sf(lakes_sf = p2_saline_lakes_sf, 
                      crs_plot = selected_crs)
  ),
  
  tar_target(
    p3_huc8_sf,
    prep_huc8_viz_sf(huc8_sf = p1_get_lakes_huc8_sf, 
                     crs_plot = selected_crs)
  )
  

)
