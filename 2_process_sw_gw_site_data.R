source('2_process/src/sites_along_waterbody.R')

p2_sw_gw_site_targets_list <- list(
  
  ## simplified vrn of all site in watersheds(regardless of whether there is relevant data at that site) + all site types
  tar_target(p2_site_in_watersheds_sf,
             p1_site_in_watersheds_sf %>% 
               select(site_tp_cd, site_no, Name, geometry)
             ),
  
  ## get just gw sites with outputed data for 2000-2020 (timeframe to change)
  tar_target(p2_nwis_dv_gw_data, 
             p1_nwis_dv_gw_data %>%
               left_join(p2_site_in_watersheds_sf, by = 'site_no') %>%
               st_as_sf() %>% 
               mutate(lon = st_coordinates(.)[,1], lat = st_coordinates(.)[,2]) %>% 
               filter(grepl('GW',site_tp_cd)) %>% 
               st_drop_geometry() %>% 
               ## quickly re-organizing cols
               select(!starts_with('X_'),starts_with('X_'))
             ),
  
  ## getting all sites along lake 
  tar_target(p2_sw_streamorder3_sites,
             sites_along_waterbody(p2_site_in_watersheds_sf,
                                   p2_lake_tributaries,
                                   lake_waterbody = FALSE)
  ),
  
  ## this takes a 5+ minutes due to time for buffer of tributaries to generate
  tar_target(p2_sw_in_lake_sites,
             sites_along_waterbody(p2_site_in_watersheds_sf,
                                   p2_saline_lakes_sf,
                                   lake_waterbody = TRUE)
             
  ),
  
  ## get just sw sites with outputed data for 2000-2020 (timeframe to change) with stream order category column
  tar_target(p2_nwis_dv_sw_data, 
             p1_nwis_dv_sw_data %>%
               left_join(p2_site_in_watersheds_sf, by = 'site_no') %>%
               filter(site_tp_cd %in% c('LK','WE') | grepl('ST',site_tp_cd)) %>% 
               mutate(stream_order_category = case_when(
                 grepl(site_tp_cd,'^ST') & site_no %in% p2_sw_streamorder3_sites ~ 'along SO 3+',
                 site_tp_cd == 'LK' | site_no %in% p2_sw_in_lake_sites ~ 'along lake',
                 TRUE ~ 'not along SO 3+'
                 )) %>% 
               st_as_sf() %>% 
               mutate(lon = st_coordinates(.)[,1], lat = st_coordinates(.)[,2]) %>% 
               st_drop_geometry() %>% 
               ## quickly re-organizing cols
               select(!starts_with('X_'),starts_with('X_'))
             
  )
  

)

  # # SW data -----------------------------------------------------------------
  # 
  # p1_nwis_dv_sw_data_sf <- p1_nwis_dv_sw_data %>% left_join(sites_simplified, by = 'site_no')
  # 
  # p1_nwis_dv_sw_data_sf$site_tp_cd %>% unique()
  # # "ST"     "ST-DCH" "LK"     "FA-DV"  "ST-CA"  NA       "SP" 
  # 
  # p1_nwis_dv_sw_data_sf %>% filter(site_tp_cd == 'FA-DV') %>% pull(site_no) %>% unique()
  # ## 1 site has SW data for site_tp_cd FA-DV
  # 
  # p1_nwis_dv_sw_data_sf %>% filter(site_tp_cd == 'SP') %>% pull(site_no) %>% unique()
  # ## 6 sites has SW data for site_tp_cd SP
  # 
  # p1_nwis_dv_sw_data_sf %>% filter(site_tp_cd == 'LK') %>% pull(site_no) %>% unique()
  # ## 10 sites has SW data for site_tp_cd SP
  # 
  # 
  # sw_sites <- p1_nwis_dv_sw_data_sf %>% 
  #   filter(site_tp_cd %in% c('ST','LK')) %>% 
  #   group_by(site_no,site_tp_cd, geometry) %>%
  #   summarize(n()) %>%
  #   st_as_sf() 
  # 
  # ## buffer tributaries
  # tributaries_buffered <- p2_lake_tributaries %>%
  #   st_buffer(1000)
  # 
  # ## buffer lakes
  # lakes_buffered <- p2_saline_lakes_sf %>% st_buffer(1000) 
  # 
  # ## join lake and tribs 
  # ## / UPDATE: This takes too long, going to skip
  # # lake_tributaries <- st_union(tributaries_buffered, lakes_buffered)
  # 
  # # filtered_sites_along_tribs<- sf::st_filter(x = sw_sites,y = tributaries_buffered,
  # #               .predicate = sf::st_is_within_distance,
  # #               dist = units::set_units(0, m))
  # ## /
  # 
  # filtered_sites_along_lk <- st_join(sw_sites, lakes_buffered, left = FALSE)
  # filtered_sites_along_tribs <- st_join(sw_sites, tributaries_buffered, left = FALSE)
  # 
  # ## st_join create tables from the lakes_buffered and tributaries buffered table - so jusing just the filter original table
  # filtered_sw_sites_sf <- sw_sites %>% filter(site_no %in% c(filtered_sites_along_tribs$site_no,filtered_sites_along_lk$site_no))
  # 
  # 
  # 
  # )
