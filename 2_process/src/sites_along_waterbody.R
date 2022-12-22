#' @param sites_sf sf object of sf sites and measurements
#' @param waterbody_sf sf object of water body that will be buffered 
#' @param lake_waterbody whether water body is lake or not

sites_along_waterbody <- function(sites_sf, waterbody_sf, lake_waterbody = FALSE){

  sites_sf <- sites_sf %>% 
    select(site_no)
  
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
  filtered_sites <- st_join(sites_sf, waterbody_buffered, left = FALSE) %>%
    pull(site_no) %>%
    unique()
  
  return(filtered_sites)
  
}

#' @title join_site_spatial_info
#' @description function that joins nwis site info to nwis sw or gw data
#' @param nwis_data nwis sw or gw data pulled from dataRetrieval::readNWISdata() or similar dataRetrieval functions 
#' @param sites_sf sf object of sf sites and measurements
#' @param join_site_col col to site col to join sites_sf with nwis_sw_data. defaults is site_no as that is expected to be common between both dfs

join_site_spatial_info <- function(nwis_data, sites_sf, join_site_col = 'site_no'){

  nwis_data %>%
    left_join(sites_sf, by = join_site_col) %>%
    ## used geometry from sites_in_watersheds_sf to get spatial info
    st_as_sf() %>% 
    ## Grab coords 
    mutate(lon = st_coordinates(.)[,1], lat = st_coordinates(.)[,2]) %>% 
    ## remove geometry col
    st_drop_geometry()
}

#' @title add_stream_order
#' @description function that joins nwis site info to nwis sw data and adds stream order col
#' @param nwis_sw_data nwis sw data pulled from dataRetrieval::readNWISdata() or similar dataRetrieval functions 
#' @param sites_along_streamorder3 vector of site_no that are along stream order 3 streams. Output of sites_along_waterbody()    
#' @param sites_along_lake vector of sites that are adjacent to saline lakes. Output of sites_along_waterbody

add_stream_order <- function(nwis_sw_data, sites_along_streamorder3, sites_along_lake){
  
  nwis_sw_data %>% 
    filter(site_tp_cd %in% c('LK','WE') | grepl('ST',site_tp_cd)) %>% 
    ## create stream_order_category col depending on site type & match with sites stream order/lake vector targets 
    mutate(
      stream_order_category = case_when(
        grepl('^ST',site_tp_cd) & site_no %in% sites_along_streamorder3 ~ 'along SO 3+',
        site_tp_cd == 'LK' | site_no %in% sites_along_lake ~ 'along lake',
        TRUE ~ 'not along SO 3+'))
}