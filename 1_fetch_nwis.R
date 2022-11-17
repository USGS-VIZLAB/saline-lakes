source('1_fetch/src/fetch_by_site_and_service.R')
source('1_fetch/src/get_NWIS_site_no.R')

p1_nw_targets_list <- list(
  
  ## Pulling site data retrieval using whatNWISsites(). 
  ## This target is a sf object can be joined to nwis datasets below via site_no 
  ## Subsetting huc8 multipolygon to simplify join in get_NWIS_site_no()
  tar_target(
    p1_site_in_watersheds_sf,
    get_NWIS_site_no(basin_huc08 = p1_basin_huc8_sf$HUC8,
                     lake_watershed_sf = p2_huc10_watershed_boundary,
                     crs = p0_selected_crs)
    ),
  
  ##############################################################################
  # NWIS Data Queries
  
  ## Target to allow branching across lakes
  tar_target(
    p1_site_no_by_lake,
    {p1_site_in_watersheds_sf %>%
        st_drop_geometry() %>% 
        select(lake_w_state, site_no) %>%
        distinct() %>%
        group_by(lake_w_state) %>% 
        tar_group()
    },
    iteration = 'group'
  ),
  
  # SW
  
  # SW - field measurements - - branched by lake with grouped target p1_site_no_by_lake
  ## output target is a list of dfs split by lake name. second target is list binded
  
  # list of dfs
  tar_target(
    p1_nwis_meas_sw_data_lst,
    fetch_by_site_and_service(sites_df = p1_site_no_by_lake,
                              sites_col = 'site_no',
                              lake_col = 'lake_w_state',
                              ## note - for service = measurements, pcodes are irrelevant because 
                              ## we are pulling specific surface water measurement function readNWISmeas()
                              pcodes = p0_sw_params,
                              service = 'measurements',
                              start_date = p0_start,
                              end_date = p0_end),
    pattern = map(p1_site_no_by_lake),
    iteration = 'list'
  ),
  
  ## creating single df
  tar_target(
    p1_nwis_meas_sw_data,
    p1_nwis_meas_sw_data_lst %>%
      ## making measurement_nu col same type to allow rbind
      map(~ mutate(.x, across(starts_with('measurement_nu'), as.character))) %>% 
      bind_rows()
  ),
  
  ## xwalk branch to lake for sw meas
  tar_target(
    p1_br_lk_xwalk_meas_sw,
    tibble(branch_name = names(p1_nwis_dv_sw_data_lst),
           lake_names = p1_site_no_by_lake %>% arrange(tar_group) %>% pull(lake_w_state) %>% unique())
  ),
  
  # SW - dv - branched by lake with grouped target p1_site_no_by_lake
  ## output target is a list of dfs split by lake name. second target is that list of dfs binded
  
  # list of dfs
  tar_target(
    p1_nwis_dv_sw_data_lst,
    fetch_by_site_and_service(sites_df = p1_site_no_by_lake,
                              sites_col = 'site_no',
                              lake_col = 'lake_w_state',
                              pcodes = p0_sw_params,
                              service = 'dv',
                              start_date = p0_start,
                              end_date = p0_end),
    pattern = map(p1_site_no_by_lake),
    iteration = 'list'
  ),
  
  
  tar_target(
    p1_br_lk_xwalk_dv_sw,
    tibble(branch_name = names(p1_nwis_dv_sw_data_lst),
           lake_names = p1_site_no_by_lake %>% arrange(tar_group) %>% pull(lake_w_state) %>% unique())
  ),
    
  ## creating single df
  tar_target(
    p1_nwis_dv_sw_data,
    p1_nwis_dv_sw_data_lst %>% 
      bind_rows()
  ),
  
  # SW - iv - branched by lake with specifically created grouped target p1_site_no_by_lake_sw_iv
  ## dv data is summarized from iv data, therefore any site with dv data will have iv data and vis versa
  ## iv data is much heavier so we provided a filtered list from dv to lighten the load of request
  
  ## Used `bind_rows()` to bind list into df (maybe data.table works better given size of df) 
  ## and group_by() lake name (lake_w_state) to summarize results by lake.

  ## Specific mapping target for sw iv data fetch
  tar_target(
    p1_site_no_by_lake_sw_iv,
    {p1_nwis_dv_sw_data %>%  
        select(lake_w_state, site_no) %>%
        distinct() %>%
        group_by(lake_w_state) %>% 
        tar_group()
    },
    iteration = 'group'
  ),
  
  ## Fetch iv data
  tar_target(
    p1_nwis_iv_sw_data_lst,
    fetch_by_site_and_service(sites_df = p1_site_no_by_lake_sw_iv,
                              sites_col = 'site_no',
                              lake_col = 'lake_w_state',
                              pcodes = p0_sw_params,
                              service = 'iv',
                              start_date = p0_start,
                              end_date = p0_end,
                              incrementally = TRUE,
                              split_num = 10),
    pattern = map(p1_site_no_by_lake_sw_iv),
    iteration = 'list'
  ),
  
  ## Fetch iv data
  tar_target(
    p1_nwis_iv_sw_data_lst_shrt,
    fetch_by_site_and_service(sites_df = p1_site_no_by_lake_sw_iv,
                              sites_col = 'site_no',
                              lake_col = 'lake_w_state',
                              pcodes = p0_sw_params,
                              service = 'iv',
                              start_date = '2015-01-01',
                              end_date = '2016-01-01',
                              incrementally = TRUE,
                              split_num = 10),
    pattern = map(p1_site_no_by_lake_sw_iv),
    iteration = 'list'
  ),
  
  tar_target(
    p1_br_lk_xwalk_iv_sw,
    tibble(branch_name = names(p1_nwis_iv_sw_data_lst),
           lake_names = p1_site_no_by_lake_sw_iv %>% arrange(tar_group) %>% pull(lake_w_state) %>% unique())
  )
    
   
   
  # GW #
  
  # GW - field measurements - - branched by lake with grouped target p1_site_no_by_lake
  ## Use `bind_rows()` to bind list into single df and group_by() lake name (lake_w_state) to summarize results by lake.
  
  # tar_target(
  #   p1_nwis_meas_gw_data,
  #   fetch_by_site_and_service(sites_df = p1_site_no_by_lake,
  #                             sites_col = 'site_no',
  #                             lake_col = 'lake_w_state',
  #                             pcodes = p0_gw_params,
  #                             service = 'gwlevels',
  #                             start_date = p0_start,
  #                             end_date = p0_end),
  # pattern = map(p1_site_no_by_lake),
  # iteration = 'list'
  # )
  
  # GW - dv - branched by lake with grouped target p1_site_no_by_lake
  ## Use `bind_rows()` to bind list into df and group_by() lake name (lake_w_state) to summarize results by lake.

  # tar_target(
  #   p1_nwis_dv_gw_data,
  #   fetch_by_site_and_service(sites_df = p1_site_no_by_lake,
  #                             sites_col = 'site_no',
  #                             lake_col = 'lake_w_state',
  #                             pcodes = p0_gw_params,
  #                             service = 'dv',
  #                             start_date = p0_start,
  #                             end_date = p0_end),
  # pattern = map(p1_site_no_by_lake),
  # iteration = 'list'
  # ),
  
   
  # GW - iv - branched by lake with newly created grouped target p1_site_no_by_lake_gw_iv
  ## dv data is summarized from iv data, therefore any site with dv data will have iv data and vis versa
  ## Given this and that iv data is much heavier so we provided a filtered list to lighten the load of request

  # first - building smaller mapping target for gw iv data fetch 
  # tar_target(
  #   p1_site_no_by_lake_gw_iv,
  #   {p1_nwis_dv_gw_data %>%
  #       bind_rows() %>% 
  #       select(lake_w_state, site_no) %>%
  #       distinct() %>%
  #       group_by(lake_w_state) %>% 
  #       tar_group()
  #   },
  #   iteration = 'group'
  # ),
  
  # tar_target(
  #   p1_nwis_iv_gw_data,
  #   fetch_by_site_and_service(sites_df = p1_site_no_by_lake_gw_iv,
  #                             sites_col = 'site_no',
  #                             lake_col = 'lake_w_state',
  #                             pcodes = p0_gw_params,
  #                             service = 'iv',
  #                             start_date = p0_start,
  #                             end_date = p0_end),
  # pattern = map(p1_site_no_by_lake_gw_iv),
  # iteration = 'list'
  # )
  # 

)

