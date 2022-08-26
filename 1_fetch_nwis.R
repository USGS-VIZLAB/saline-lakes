source('1_fetch/src/fetch_by_site_and_service.R')
source('1_fetch/src/get_NWIS_site_no.R')

p1_nw_targets_list <- list(
  
  # Pulling site data retrieval using whatNWISsites(). This target is a sf object can be joined to nwis datasets below via site_no 
  ## subsetting huc8 multipolygon to simplify join in get_NWIS_site_no() 
  tar_target(
    p1_site_in_watersheds_sf,
    get_NWIS_site_no(basin_huc08 = p1_huc08_full_basin_sf$huc8,
                     lake_watershed_sf = p1_get_lakes_huc8_sf %>% select(HUC8, geom), 
                     crs = selected_crs) %>% 
      # filtering point to only those within the watershed area
      st_join(., p2_lake_watersheds_dissolved,
              join = st_within, left = FALSE)
  ),
  
  tar_target(
    p1_site_no,
    {p1_site_in_watersheds_sf %>% pull(site_no) %>% unique()}
  ),
  
  ###################
  # NWIS Data Queries
  
  # SW
  ## SW - dv
  tar_target(
    p1_nwis_dv_sw_data,
    fetch_by_site_and_service(sites = p1_site_no,
                              pcodes = p0_sw_params,
                              service = 'dv',
                              start_date = p0_start,
                              end_date = p0_end)
  ),
  
  ## SW - iv
  ## dv data is summarized from iv data, therefore any site with dv data will have iv data and vis versa
  ## iv data is much heavier so we provided a filtered list to lighten the load of request
  tar_target(
    p1_nwis_iv_sw_data,
    fetch_by_site_and_service(sites = unique(p1_nwis_dv_sw_data$site_no)[1:10],
                              pcodes = p0_sw_params,
                              service = 'iv',
                              start_date = p0_start,
                              end_date = p0_end,
                              incrementally = TRUE,
                              split_num = 10)
  ),
  
  ## SW - field measurements
  tar_target(
    p1_nwis_meas_sw_data,
    fetch_by_site_and_service(sites = p1_site_no,
                              ## note - for service = measurements, pcodes is irrelevant
                              pcodes = p0_sw_params,
                              service = 'measurements',
                              start_date = p0_start,
                              end_date = p0_end)
  ),
  
  # GW
  ## GW - dv
  tar_target(
    p1_nwis_dv_gw_data,
    fetch_by_site_and_service(sites = p1_site_no,
                              pcodes = p0_gw_params,
                              service = 'dv',
                              start_date = p0_start,
                              end_date = p0_end)
  ),
  
  ## GW - iv
  ## dv data is summarized from iv data, therefore any site with dv data will have iv data and vis versa
  ## iv data is much heavier so we provided a filtered list to lighten the load of request
  tar_target(
    p1_nwis_iv_gw_data,
    fetch_by_site_and_service(sites = unique(p1_nwis_dv_gw_data$site_no),
                              pcodes = p0_gw_params,
                              service = 'iv',
                              start_date = p0_start,
                              end_date = p0_end)
  ),
  
  tar_target(
    p1_nwis_meas_gw_data,
    fetch_by_site_and_service(sites = p1_site_no,
                              pcodes = p0_gw_pcodes,
                              service = 'gwlevels',
                              start_date = p0_start,
                              end_date = p0_end)
  )
)

