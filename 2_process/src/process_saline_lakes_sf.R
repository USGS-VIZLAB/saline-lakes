process_saline_lakes_sf<- function(nhdhr_waterbodies, lakes_sf, states_sf, selected_crs){
  
  #'@description function processes nhd hr lakes with specific lakes of interest. Output is an lakes polygon sf object of our ~27 lakes
  #'@param nhdhr_waterbodies downloaded nhd hr water body data for teh selected huc regions
  #'@param states_sf states sf object
  #'@param lakes_sf lakes df object that lists lakes and lat long (from Lakes List csv)
  
  ## Cleaning dataframe
  nhdhr_saline_lakes_sf <- nhdhr_waterbodies %>%
    filter(GNIS_Name %in% lakes_sf$lake) %>%
    st_zm() %>%
    st_make_valid() %>%
    st_transform(crs = st_crs(lakes_sf)) %>% 
    st_join(x = ., y = states_sf) %>% 
    mutate(lake_w_state = paste(GNIS_Name, STATE_ABBR, sep = ',')) %>% 
    filter(lake_w_state %in% lakes_sf$lake_w_state)
  
  ## filter out incorrect lakes (e.g. eagles lakes in CA) using the lat long of Lakes and spatial join
  buf_nhdhr_saline_lakes_sf <- nhdhr_saline_lakes_sf %>% st_buffer(dist = 10^4) %>% st_join(y = lakes_sf) %>% filter(!is.na(lake))
  
  ## Spatial group by
  lakes_sf_nhdhr <- nhdhr_saline_lakes_sf %>%
    filter(GNIS_ID %in% buf_nhdhr_saline_lakes_sf$GNIS_ID) %>% 
    group_by(lake_w_state,GNIS_Name) %>%
    summarize(geometry = st_union(Shape)) %>% 
    ungroup()
  
  ## Handling Lake Winnemucca which does not exist in nhd hr
  Winnemucca <- get_waterbodies(AOI = st_sfc(lakes_sf$point_geometry[lakes_sf$lake =='Winnemucca Lake'],
                                             crs = selected_crs))
  
  ## Handling Owen's lake which does not exist in nhd hr
  Owen <- get_waterbodies(AOI = st_sfc(lakes_sf$point_geometry[lakes_sf$lake == 'Owens Lake'], 
                                       crs = selected_crs))
  
  ## Handling Warner lakes wetlands which is made u of collection of shallow wetland lakes. Full list taken from https://www.blm.gov/visit/warner-wetlands
  Warner_lakes_sf <- c('Pelican Lake',
                    'Crump Lake',
                    'Hart Lake',
                    'Anderson Lake',
                    'Swamp Lake',
                    'Mugwump Lake',
                    'Flagstaff Lake',
                    'Upper Campbell Lake',
                    'Campbell Lake',
                    'Stone Corral Lake',
                    'Turpin Lake', 
                    'Bluejoint Lake')
  
  # there are two OR swamp lakes - id-ed the incorrect one and removed in following code chunk 
  wrong_swamp_lake_id <- '142134706'
  # wrong_eagle_lake_id <- 
  Warner <-  nhdhr_waterbodies %>% 
    filter(GNIS_Name %in% Warner_lakes_sf,
           Permanent_Identifier != wrong_swamp_lake_id) %>% 
    st_zm() %>% 
    st_make_valid() %>%
    st_transform(crs = st_crs(lakes_sf)) %>% 
    st_join(x = ., y = states_sf) %>% 
    mutate(lake_w_state = paste('Warner Lake', STATE_ABBR, sep = ',')) %>% 
    filter(lake_w_state %in% lakes_sf$lake_w_state) 
  
  Warner_lakes_sf <- Warner %>%
    group_by(lake_w_state) %>%
    summarize(geometry = st_union(Shape)) %>% 
    ungroup()
  
  final_lakes <- lakes_sf_nhdhr %>% 
    add_row(lake_w_state = 'Winnemucca Lake,NV',
            GNIS_Name = 'Winnemucca Lake',
            geometry = Winnemucca$geometry[1]) %>%
    filter(GNIS_Name != 'Warner Lake') %>% 
    add_row(lake_w_state = Warner_lakes_sf$lake_w_state[1],
            GNIS_Name = 'Warner Lakes',
            geometry = Warner_lakes_sf$geometry[1]) %>%
    add_row(lake_w_state = 'Owens Lake,CA',
            GNIS_Name = 'Owens Lake',
            geometry = Owen$geometry[1]) %>%
    mutate(X = st_coordinates(st_centroid(geometry))[,1],
           Y = st_coordinates(st_centroid(geometry))[,2]) %>% 
    mutate(flag = ifelse(GNIS_Name == 'Winnemucca Lake','nhd',
                         ifelse(GNIS_Name == 'Warner lakes',
                                'From nhd hr. The Warner lakes (aka Warner Wetlands) consist of 12 shallow lakes in South East Oregon, and include Pelican, Crump, Hart lakes, among others', 'From nhd hr')))
  
  del(buf_nhdhr_saline_lakes_sf)
  
  
  return(final_lakes)
  
}
