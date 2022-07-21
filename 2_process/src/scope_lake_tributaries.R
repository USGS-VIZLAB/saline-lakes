scope_lake_tributaries <- function(fline_network,
                                 lakes_sf,
                                 buffer_dist = 10000,
                                 realization = c('flowline','catchment'),
                                 stream_order = 3){

    fline_network = p1_lake_flowlines_huc8_sf
    lakes_sf = p2_saline_lakes_sf
    buffer_dist = 10000
    realization = c('flowline','catchment')
    stream_order = 3
  
  # CHECKS
  ## flines layer geometries 
  if(any(!st_is_valid(fline_network))){
    fline_network <- st_make_valid(fline_network)
    message(paste0(fline_network, 'shp geometries fixed'))
    }
  
  ## lake layer geometries 
  if(any(!st_is_valid(lakes_sf))){
    lakes_sf <- st_make_valid(lakes_sf)
    message(paste0(lakes_sf, 'shp geometries fixed'))
  }
  
  ## Match crs
  if (!st_crs(fline_network) == st_crs(lakes_sf)) {
    message('crs are different. Transforming ...')
    fline_network <- st_transform(fline_network, crs = st_crs(lakes_sf))
    if(st_crs(fline_network) == st_crs(lakes_sf)){
       message('crs now aligned')}
  } else {
    message('crs are already aligned')
  }
    
  # Comid reaches in lake = buffering by 10000 because many lakes don't have flowlines that go right into it
  ## NOTE - Chose to buffer to be able to get all incoming tribs (issues arrive around franklin lake and carson lake)
  lakes_buffered_sf <- lakes_sf %>% st_buffer(dist= buffer_dist)
  
  # get only flowlines within lake buffer
  reach_in_lake <- st_join(fline_network, lakes_buffered_sf, left =FALSE)

  # Get Upstream Tribs
  lake_UT <- get_UT(comid = reach_in_lake$comid, network = fline_network)
  
  # fetch identified upstream tributaries
  final_lake_tributaries <- get_nhdplus(comid = lake_UT, realization = 'flowline', streamorder = stream_order)
  
  return(final_lake_tributaries)
  
}
