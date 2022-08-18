source('2_process/src/process_saline_lakes_sf.R')
source('2_process/src/scope_lake_tributaries.R')


p2_targets_list <- list(

  ## Fetch and Process saline lakes via specifically built function that creates the final saline lakes shapefile 
  ## This fun not yet generalized, special handling of lakes included in fun
  ## NOTE - Change nhdhr_lakes_path param with either p1_download_nhdhr_lakes_path or p1_download_nhdhr_lakes_backup_path depending on where nhdhr lives
  
  tar_target(
    p2_saline_lakes_sf,
    process_saline_lakes_sf(nhdhr_waterbodies = p1_nhdhr_lakes,
                            lakes_sf = p1_lakes_sf,
                            states_sf = p1_states_sf,
                            selected_crs = selected_crs)
  ), 
  
  tar_target(
    p2_lake_tributaries, 
    scope_lake_tributaries(fline_network = p1_lake_flowlines_huc8_sf,
                           lakes_sf = p2_saline_lakes_sf,
     buffer_dist = 10000, realization = 'flowline', stream_order = 3)
  ),
  
  tar_target(
    p2_lake_tributaries_cat, 
    scope_lake_tributaries(fline_network = p1_lake_flowlines_huc8_sf,
                           lakes_sf = p2_saline_lakes_sf,
                           buffer_dist = 10000, realization = 'catchment', stream_order = 3)
  ),
  
  ## Creating simplified df that structured the huc10 within the HUC 8 of our selected lakes -exporting the xlsx for manual review in view of feedback
  tar_target(
    p2_huc_boundary_xwalk_df, 
    create_huc_verification_table(huc10_sf = p1_get_lakes_huc10_sf, huc10_name_col = 'Name',
                                  huc8_sf = p1_get_lakes_huc8_sf, huc8_name_col = 'Name',
                                  lake_column = 'lake_w_state')

  ),
  
  ## Target to clean p1_get_lakes_huc10_sf and remove / add huc 10s that we need   

  ## Watershed boundary
  tar_target(
    p2_huc10_watershed_boundary,
    p1_get_lakes_huc10_sf %>% distinct(HUC10, lake_w_state, .keep_all = TRUE) %>%
      ## dissolve huc10 polygons by common attribute in HUC8 (st_union does same thing but does not keep cols
      group_by(HUC8, lake_w_state) %>% summarise(.) %>% ungroup()
)

)