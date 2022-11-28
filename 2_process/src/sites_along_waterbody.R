#' @param sw_sites_sf sf object of sf sites and measurements
#' @param waterbody_sf sf object of water bosy that will be buffered 

sites_along_waterbody <- function(sw_sites_sf, waterbody_sf, lake_waterbody = FALSE){
  
  sw_sites <- sw_sites_sf %>% 
    group_by(site_no, geometry) %>%
    sf::st_as_sf() 
  
  ## running st_union for the tributary shp because it smooths the buffer and polygons are overlap less. 
  ## Not feasible for lakes due to specific selection of columns
  if(lake_waterbody == TRUE){  
  waterbody_buffered <- waterbody_sf %>% sf::st_buffer(dist = units::set_units(250, m))
  }else{
    waterbody_buffered <- waterbody_sf %>%
      group_by(comid, streamorde) %>%
      summarize(geometry = sf::st_union(geometry)) %>%
      sf::st_buffer(dist = units::set_units(250, m))
  }
  filtered_sites <- st_join(sw_sites, waterbody_buffered, left = FALSE) %>%
    pull(site_no) %>%
    unique()
  
  return(filtered_sites)
  
}
