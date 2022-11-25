scope_lake_tributaries <- function(fline_network,
                                 lakes_sf,
                                 buffer_dist = NULL,
                                 realization = 'flowline',
                                 stream_order = NULL){

  #'@description subset flowlines network to get only tributaries upstream of lakes or catchments of lake Upstream tributaries
  #'@param fline_network sf dataframe of flowlines from nhdplustools 
  #'@param lakes_sf sf dataframe of focal lake polygons
  #'@param buffer_dist buffer_dist buffer distance for lakes to ensure capture of all flowlines relevant to lake. Measurement units for the buffer depend on the CRS. The default CRS of 4326 has linear units of meters.
  #'@param realization either flowline or catchment. Must input only 1, unlike with this param in get_nhdplus() 
  #'@param stream_order stream order level. Defaults See get_nhdplus() for further details
  #'@value nhdplus sf dataframe of flowlines or catchments of reaches Upstream of focal lakes
  
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
  
  # Buffer lakes if not null  
  ## Comid reaches in lake = buffering by 10000 because many lakes don't have flowlines inside lake
  lakes_sf_noCS <- lakes_sf %>% filter(lake_w_state != "Carson Sink,NV")
  lakes_sf_CS <- lakes_sf %>% filter(lake_w_state == "Carson Sink,NV")

  if(!is.null(buffer_dist)){
    lakes_buffered_sf <- lakes_sf_noCS %>% st_buffer(dist= buffer_dist)
  } else{
    lakes_buffered_sf <- lakes_sf_noCS
  }
  
  lakes_buffered_sf <- rbind(lakes_buffered_sf, lakes_sf_CS)
  
  # Intersect to grab only flowlines within lake buffer
  reach_in_lake <- st_join(fline_network, lakes_buffered_sf, left =FALSE)

  # Get Upstream tribs - chunking to process faster without potential errors
  lake_UT <- get_UT(comid = reach_in_lake$comid, network = fline_network) %>% 
    split(., ceiling(seq_along(.)/50))
  
  print('Retrieving lake tributaries')
  
  # Running get_nhdplustools() in lake_UT chunks
  lake_tributaries <- lapply(lake_UT, function(x){
    suppressMessages(nhdplusTools::get_nhdplus(comid = x, 
                                               realization = realization,
                                               streamorder = stream_order))
    }) %>%
    do.call(rbind, .)
  
  return(lake_tributaries)
}
