source('3_visualize/src/prep_viz_data.R')
source('3_visualize/src/interactive_map.R')
source('3_visualize/src/generate_spreadsheet.R')


p3_targets_list <- list(

  ## Fetch and Process saline lakes via specifically built function that creates the final saline lakes shapefile 
  ## This fun not yet generalized, special handling of lakes included in fun
  ## NOTE - Change nhdhr_lakes_path param with either p1_download_nhdhr_lakes_path or p1_download_nhdhr_lakes_backup_path depending on where nhdhr lives
  tar_target(
    assc_lakes_df,
    assc_lakes_xwalk_df(huc8_sf = p1_get_lakes_huc8_sf)
  ),
  
  tar_target(
    p3_saline_lakes_sf,
    prep_lakes_viz_sf(lakes_sf = p2_saline_lakes_sf, 
                      crs_plot = selected_crs)
  ),
  
  tar_target(
    p3_huc8_sf,
    prep_huc8_viz_sf(huc8_sf = p1_get_lakes_huc8_sf,
                     assc_lakes_df = assc_lakes_df,
                     crs_plot = selected_crs)
  ),
  
  tar_target(
    p3_flowlines_sf,
    prep_flowlines_viz_sf(flowlines_sf = p2_lake_tributaries, 
                          crs_plot = selected_crs)
  ),
  
  tar_target(
    p3_gage_sites_sf,
    prep_gage_viz_sf(nwis_sites = p1_nwis_sites, 
                     huc8_sf = p3_huc8_sf, 
                     crs_plot = selected_crs)
  ),
  
  tar_target(
    p3_feedback_spreadsheet_xlsx,
    build_feedback_spreadsheet(p1_get_lakes_huc8_sf = p1_get_lakes_huc8_sf,
                               p3_flowlines_sf = p3_flowlines_sf, 
                               assc_lakes_df = assc_lakes_df,
                               out_file = "3_visualize/out/Subbasin_KeepDiscard.xlsx"),
    format = "file"
  ),
  
  tar_target(
    p3_interactive_map_leaflet,
    build_map_leaflet(p3_huc8_sf = p3_huc8_sf, 
                      p3_saline_lakes_sf = p3_saline_lakes_sf, 
                      p3_flowlines_sf = p3_flowlines_sf, 
                      p3_gage_sites_sf = p3_gage_sites_sf)
    
  )
)
