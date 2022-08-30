source('1_fetch/src/fetch_by_site_and_service.R')
source('1_fetch/src/get_NWIS_site_no.R')

p1_nw_targets_list <- list(
  
  # Pulling site data retrieval using whatNWISsites(). This target is a sf object can be joined to nwis datasets below via site_no 
  ## subsetting huc8 multipolygon to simplify join in get_NWIS_site_no()
  tar_target(
    p1_site_in_watersheds_sf,
    get_NWIS_site_no(basin_huc08 = p1_huc08_full_basin_sf$huc8,
                     lake_watershed_sf = p2_huc10_watershed_boundary,
                     crs = selected_crs)
    ),
  
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
  
  ###################
  # NWIS Data Queries
  
  # SW
  
  # SW - field measurements - - branched by lake with grouped target p1_site_no_by_lake
  ## Time: This took about  <3 min for all ~15,000. Note: many sites have field data. 
  tar_target(
    p1_nwis_meas_sw_data,
    fetch_by_site_and_service(sites = p1_site_no_by_lake,
                              ## note - for service = measurements, pcodes is irrelevant
                              pcodes = p0_sw_params,
                              service = 'measurements',
                              start_date = p0_start,
                              end_date = p0_end),
    pattern = map(p1_site_no_by_lake),
    iteration = 'list'
  ),
  
  # SW - dv - branched by lake with grouped target p1_site_no_by_lake
  ## Time: This took about  <25 min for all 15,000 sites. Note: many sites have no data. 
  tar_target(
    p1_nwis_dv_sw_data,
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
  
  # SW - iv - branched by lake with newly created grouped target p1_site_no_by_lake_sw_iv
  ## dv data is summarized from iv data, therefore any site with dv data will have iv data and vis versa
  ## iv data is much heavier so we provided a filtered list from dv to lighten the load of request
  ## Time: This took about  <45 min for all unique sites (length(unique(p1_nwis_dv_sw_data$site_no)) = 263). Note: many sites have no data. 
  
  ## Specific mapping target for sw iv data fetch
  tar_target(
    p1_site_no_by_lake_sw_iv,
    {p1_nwis_dv_sw_data %>%
        bind_rows() %>% 
        select(lake_w_state, site_no) %>%
        distinct() %>%
        group_by(lake_w_state) %>% 
        tar_group()
    },
    iteration = 'group'
  ),
  
  ## Fetch iv data
  tar_target(
    p1_nwis_iv_sw_data,
    fetch_by_site_and_service(sites_df = p1_site_no_by_lake_iv,
                              sites_col = 'site_no',
                              lake_col = 'lake_w_state',
                              pcodes = p0_sw_params,
                              service = 'iv',
                              start_date = p0_start,
                              end_date = p0_end,
                              incrementally = TRUE,
                              split_num = 10),
    pattern = map(p1_site_no_by_lake_iv),
    iteration = 'list'
  ),
   
   
  # GW
  
  # GW - field measurements - - branched by lake with grouped target p1_site_no_by_lake

  # tar_target(
  #   p1_nwis_meas_gw_data,
  #   fetch_by_site_and_service(sites = p1_site_no_by_lake,
  #                             pcodes = p0_gw_params,
  #                             service = 'gwlevels',
  #                             start_date = p0_start,
  #                             end_date = p0_end),
  # pattern = map(p1_site_no_by_lake),
  # iteration = 'list'
  # )
  
  # GW - dv - branched by lake with grouped target p1_site_no_by_lake
  ## Time: This took 1 min for all ~15,000 sites . Note many are empty it is 1 gw param and gw is more data sparse than sw

  # tar_target(
  #   p1_nwis_dv_gw_data,
  #   fetch_by_site_and_service(sites = p1_site_no_by_lake,
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
  ## Time: this took m 15 min for all 69 unique sites (length(unique(p1_nwis_dv_gw_data$site_no) = 69)
  
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
  #   fetch_by_site_and_service(sites = p1_site_no_by_lake_gw_iv,
  #                             pcodes = p0_gw_params,
  #                             service = 'iv',
  #                             start_date = p0_start,
  #                             end_date = p0_end),
  # pattern = map(p1_site_no_by_lake_gw_iv),
  # iteration = 'list'
  # ),
  # 

)

