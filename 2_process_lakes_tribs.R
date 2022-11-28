source('2_process/src/process_saline_lakes_sf.R')
source('2_process/src/scope_lake_tributaries.R')

## Scripts grabs geospatial data targets created in fetch scripts 1_fetch_spatial.R and processes 2 new targets: 
## 1. p2_saline_lakes_sf : final sf object representing our focal saline lakes. Fun process_saline_lakes_sf() is
## not generalized, and you will find input-specific commands and processing steps ther
##
## 2. p2_lake_tributaries : polylines object representing all upstream tributaries of the lakes - creating using nhdplusTools Get_UT() function (UT:upstream)
## 3. p2_lake_tributaries_cat: polygon object representing all upstream nhd catchments. Current target is not used downstream

p2_lakes_tribs_targets_list <- list(

  # Create and process main lakes sf target #
  ## Fetch and process saline lakes via specifically built function that creates the final saline lakes shapefile 
  ## This fun not yet generalized, special handling of lakes included in fun
  ## Note - this target is fed back into 1_fetch_spatial.R
  
  tar_target(
    p2_saline_lakes_sf,
    process_saline_lakes_sf(nhdhr_waterbodies = p1_nhdhr_lakes,
                            lakes_sf = p1_lakes_sf,
                            states_sf = p1_states_sf,
                            selected_crs = p0_selected_crs) %>%
    bind_rows(p1_saline_lakes_bnds_sf %>%
                  filter(GNIS_Name == 'Carson Sink') %>%
                mutate(X = unlist(st_centroid(geometry))[1],
                       Y = unlist(st_centroid(geometry))[2]))
  ),
  
  # Basin Flowlines Processing #
  ## Get only tributaries of the Lakes using get_UT function
  tar_target(
    p2_lake_tributaries, 
    scope_lake_tributaries(fline_network = p1_lake_flowlines_huc8_sf,
                           lakes_sf = p2_saline_lakes_sf,
                           buffer_dist = 10000,
                           realization = 'flowline',
                           stream_order = 3) %>% 
      filter(streamorde >= 3)
  ),
  
  ## Get only tributaries of the Lakes using get_UT function 
  ### No downstream use atm
  # tar_target(
  #   p2_lake_tributaries_cat, 
  #   scope_lake_tributaries(fline_network = p1_lake_flowlines_huc8_sf,
  #                          lakes_sf = p2_saline_lakes_sf,
  #                          buffer_dist = 10000,
  #                          realization = 'catchment',
  #                          stream_order = 3)
  # 
  # ),
  
  ## Get only tributaries of the Lakes using get_UT function 
  ### No downstream use atm
  tar_target(
    p2_lake_tributaries_cat, 
    scope_lake_tributaries(fline_network = p1_lake_flowlines_huc8_sf,
                           lakes_sf = p2_saline_lakes_sf,
                           buffer_dist = 10000,
                           realization = 'catchment',
                           stream_order = 3)
    )
    
 
)