get_NWIS_site_no <- function(basin_huc08, lake_watershed_sf, crs){
  
  #' @param basin_huc08 vector of all huc08 of the lakes' Great Basin region
  #' @param lake_watershed_sf lake watershed multipolygon 
  #' @param selected_crs crs of the shapefile
  
  # basin_huc08 = p1_huc08_full_basin_sf$huc8
  # lake_watershed_sf = p2_huc10_watershed_boundary
  # crs = 4326
  
  ## Extract sites
  huc_grps <- split(basin_huc08,
                    ceiling(seq_along(basin_huc08)/10))
  
  sites_df <- lapply(huc_grps, function(huc08){
    dataRetrieval::whatNWISsites(huc = huc08)}) %>% 
    bind_rows()
  
  sites_sf <- sites_df %>% st_as_sf(coords = c("dec_long_va", "dec_lat_va"),
                                    crs = crs)
  
  ## Match crs
  if(st_crs(sites_sf) != st_crs(lake_watershed_sf)){
    stop('CRS error. crs must be same as crs of lake_watershed_sf')
  }
  
  ## filter sites to only those within watershed (multi)polygons
  sites_in_watersheds <- st_join(sites_sf,lake_watershed_sf, left = FALSE) %>%
    distinct(site_no, .keep_all = TRUE)
  
  return(sites_in_watersheds)
  
}
