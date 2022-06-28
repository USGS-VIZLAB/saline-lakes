
process_saline_lakes_sf_sf<- function(nhdhr_waterbodies, lakes_sf_sf, states_sf_sf, selected_crs){
  
  ## Cleaning dataframe
  nhdhr_saline_lakes_sf <- nhdhr_waterbodies %>%
    filter(GNIS_Name %in% lakes_sf_sf$lake) %>%
    st_zm() %>%
    st_make_valid() %>%
    st_transform(crs = st_crs(lakes_sf)) %>% 
    st_join(x = ., y = states_sf) %>% 
    mutate(lake_w_state = paste(GNIS_Name, STATE_ABBR, sep = ',')) %>% 
    filter(lake_w_state %in% lakes_sf$lake_w_state)
  
  ## Spatial group by
  lakes_sf_nhdhr <- nhdhr_saline_lakes_sf %>%
    group_by(lake_w_state,GNIS_Name) %>%
    summarize(geometry = st_union(Shape)) %>% 
    ungroup()
  
  ## Handling Lake Winnemucca which does not exist in nhd hr
  Winnemucca <- get_waterbodies(AOI = st_sfc(lakes_sf$point_geometry[lakes_sf$lake =='Winnemucca Lake'],
                                             crs = selected_crs))
  
  ## Handling Owen's lake which does not exist in nhd hr
  Owen <- get_waterbodies(AOI = st_sfc(lakes_sf$point_geometry[lakes_sf$lake == 'Owens Lake'], 
                                       crs = selected_crs))
  
  ## Handling Warner lakes_sf/wetlands which is made u of collection of shallow wetland lakes_sf. Full list taken from https://www.blm.gov/visit/warner-wetlands
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
  
  # there are two OR swamp lakes_sf - id-ed the incorrect one and removed in following code chunk 
  wrong_swamp_lake_id <- '142134706'
  
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
            GNIS_Name = 'Warner lakes_sf',
            geometry = Warner_lakes_sf$geometry[1]) %>%
    add_row(lake_w_state = 'Owens Lake,CA',
            GNIS_Name = 'Owens Lake',
            geometry = Owen$geometry[1]) %>%
    mutate(X = st_coordinates(st_centroid(geometry))[,1],
           Y = st_coordinates(st_centroid(geometry))[,2]) %>% 
    mutate(flag = ifelse(GNIS_Name == 'Winnemucca Lake','nhd',
                         ifelse(GNIS_Name == 'Warner lakes_sf',
                                'From nhd hr. The Warner lakes_sf (aka Warner Wetlands) consist of 12 shallow lakes_sf in South East Oregon, and include Pelican, Crump, Hart lakes_sf, among others', 'From nhd hr')))
  
  return(final_lakes)
  
}
