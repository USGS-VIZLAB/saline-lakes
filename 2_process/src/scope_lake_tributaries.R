scope_lake_tributaries <- function(fline_network,
                                 lakes_sf,
                                 buffer_dist = 1000000,
                                 realization = c('flowline','catchment'),
                                 stream_order = 3){

  # Comid reaches in lake = buffering by 10000 because many lakes don't have flowlines that go right into it
  
  lakes_buffered_sf <- lakes_sf %>% st_buffer(dist= 10000)
  reach_in_lake <- st_join(fline_network, lakes_buffered_sf, left =FALSE)
  
  ## NOTE - Chose to buffer to be able to get all incoming tribs (issues arrive around franklin lake and carson lake)
  # Get Upstream Tribs
  lake_UT <- get_UT(comid = reach_in_lake$comid, network = fline_network)
  
  final_lake_tributaries <- get_nhdplus(comid = lake_UT, realization = realization, streamorder = stream_order)
  
  return(final_lake_tributaries)
  
}