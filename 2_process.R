source('2_process/src/process_saline_lakes_sf.R')
source('2_process/src/scope_lake_tributaries.R')


p2_targets_list <- list(

  ## Fetch and Process saline lakes via specifically built function that creates the final saline lakes shapefile 
  ## This fun not yet generalized, special handling of lakes included in fun
  
  tar_target(
    p2_saline_lakes_sf,
    process_saline_lakes_sf(nhdhr_waterbodies = p1_nhdhr_lakes,
                            lakes_sf = p1_lakes_sf,
                            states_sf = p1_states_sf,
                            selected_crs = selected_crs) %>%
    bind_rows(p1_saline_lakes_bnds_sf %>%
                  filter(GNIS_Name == 'Carson Sink'))
  ),
  
  ## Creating simplified df that structures the huc10 within the HUC 8 of our selected lakes -exporting the xlsx for manual review in view of feedback
  tar_target(
    p2_huc_boundary_xwalk_df, 
    create_huc_verification_table(huc10_sf = p1_get_lakes_huc10_sf,
                                  huc10_name_col = 'Name',
                                  huc8_sf = p1_get_lakes_huc8_sf,
                                  huc8_name_col = 'Name',
                                  huc6_sf = p1_get_lakes_huc6_sf,
                                  huc6_name_col = 'Name',
                                  lake_column = 'lake_w_state')
  ),
  
  ## Get only tributaries of the Lakes using get_UT function
  tar_target(
    p2_lake_tributaries, 
    scope_lake_tributaries(fline_network = p1_lake_flowlines_huc8_sf,
                           lakes_sf = p2_saline_lakes_sf,
     buffer_dist = 10000,
     realization = 'flowline',
     stream_order = 3)
  ),
  
  tar_target(
    p2_lake_tributaries_cat, 
    scope_lake_tributaries(fline_network = p1_lake_flowlines_huc8_sf,
                           lakes_sf = p2_saline_lakes_sf,
                           buffer_dist = 10000,
                           realization = 'catchment',
                           stream_order = 3)
  ),
  
  ## Target to clean p1_get_lakes_huc10_sf and remove / add huc 10s that we need for our watershed boundary   
  ## Note: moved lakes_huc6_huc8_huc10_structure_table to the 1_fetch/in/ to be able to read in the manually edited excel
  tar_target(
    p2_huc_manual_verification_df,
      readxl::read_excel('1_fetch/in/lake_huc6_huc8_huc10_structure_table.xlsx',
               col_types = 'text') %>% 
      mutate(`Part of Watershed (Yes/No)` = tolower(`Part of Watershed (Yes/No)`)) %>%
      filter(`Part of Watershed (Yes/No)` == 'yes')
  ),
  
  # creating vector of common cols to avoid duplicating cols in left join below 
  tar_target(
    p2_common_cols,
    intersect(names(p2_huc_manual_verification_df), names(p1_get_lakes_huc10_sf))
  ),
  
  ## Watershed boundary ungrouped df
  tar_target(
    p2_huc10_watershed_boundary,
    p2_huc_manual_verification_df %>% 
      # Joining two df avoiding creating duplicate cols
      left_join(p1_get_lakes_huc10_sf %>%
                  select(!p2_common_cols, 'HUC10'),
                by = 'HUC10') %>%
      sf::st_as_sf() %>% 
    distinct(HUC10, lake_w_state,
             .keep_all = TRUE)
  ),
  
  ## Dissolved watershed boundary
  ## Dissolve huc10 polygons by common attribute in HUC8 (st_union is applied here, as group by but group by keeps all columns
  tar_target(
    p2_lake_watersheds_dissolved,
    p2_huc10_watershed_boundary %>% 
        group_by(lake_w_state) %>%
      summarize(geometry = sf::st_union(geom)) %>%
      ungroup()
  )
)