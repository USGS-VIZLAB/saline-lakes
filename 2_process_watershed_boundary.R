
p2_watershed_boundary_targets_list <- list(
  
  # Watershed boundary creation #

  ## We created a verification target (p2_huc_manual_verification_df) which serves to zone-in on HUCs
  ## that ultimately define our lake watershed boundary   
  ## Note: we MANUALLY edited HUCs in/out scope and then moved it `lakes_huc6_huc8_huc10_structure_table.xlsx` to the 1_fetch/in/
  ## Note: If the lake excel is edited (e.g. you change a yes/no), you must force build of this target to see change. Target does not notice changes made to the spreadsheet since it is done off-pipeline 
  
  ## watershed extent data table - this is the edited version of the raw p1_lake_huc6_huc8_huc10_structure_xlsx
  tar_target(p2_path_lake_huc6_huc8_huc10_structure_table,
             '1_fetch/in/lake_huc6_huc8_huc10_structure_table.xlsx'
  ),
  
  tar_target(
    p2_huc_manual_verification_df,
    readxl::read_excel(p2_path_lake_huc6_huc8_huc10_structure_table,
                       col_types = 'text') %>%
      mutate(`Part of Watershed (Yes/No)` = tolower(`Part of Watershed (Yes/No)`)) %>% # running a tolower to catch diff manual inputs in excel
      filter(`Part of Watershed (Yes/No)` == 'yes')
  ),
  
  # creating vector of common cols to avoid duplicating cols in left join below 
  tar_target(
    p2_common_cols,
    intersect(names(p2_huc_manual_verification_df), 
              names(p1_lakes_huc10_sf))
  ),
  
  ## Watershed boundary targets by Huc10 - (not dissolved)
  tar_target(
    p2_huc10_watershed_boundary,
    p2_huc_manual_verification_df %>% 
      # Joining two df while avoiding the creation of duplicate cols
      left_join(p1_lakes_huc10_sf %>%
                  select(!all_of(p2_common_cols), 'HUC10'),
                by = 'HUC10') %>%
      sf::st_as_sf() %>% 
      # eliminate duplicate huc10s per lake (p1_lakes_huc10_sf) - some instances nhdplusTools dfs have multiple rows
      distinct(HUC10, lake_w_state,
               .keep_all = TRUE)
  ),
  
  
  ## Lake watershed boundaries - Dissolved
  ### Note dissolve is done by the lake_w_state attr - no other attributes stay. Output sf object is a multi-polygon obj where each lake belongs to  1 polygon
  tar_target(
    p2_lake_watersheds_dissolved,
    p2_huc10_watershed_boundary %>% 
      group_by(lake_w_state) %>%
      summarize(geometry = sf::st_union(geom)) %>%
      ungroup()
  )
  
)