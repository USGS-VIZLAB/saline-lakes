
process_saline_lakes_sf<- function(nhdhr_lakes_path, lakes_sf, states_sf, selected_crs){
  
  # nhdhr_lakes_path = p1_download_nhdhr_lakes_backup_download_path
  # lakes_sf = lakes
  # states_sf = states
  # selected_crs = 4326
  
  lakes <- lakes_sf
  states <- states_sf
  
  
  ## nhdplustools download data if you have not done so.
  # source('Data/Download_nhd.R'
  
  nhd_hr <- nhdplusTools::get_nhdplushr(hr_dir = nhdhr_lakes_path,
                                        layer= 'NHDWaterbody')
  
  ## Cleaning dataframe
  nhdhr_saline_lakes <- nhd_hr$NHDWaterbody %>%
    filter(GNIS_Name %in% lakes$lake) %>%
    st_zm() %>%
    st_make_valid() %>%
    st_transform(crs = st_crs(lakes)) %>% 
    st_join(x = ., y = states) %>% 
    mutate(lake_w_state = paste(GNIS_Name, STATE_ABBR, sep = ',')) %>% 
    filter(lake_w_state %in% lakes$lake_w_state)
  
  ## Spatial group by
  lakes_nhdhr <- nhdhr_saline_lakes %>%
    group_by(lake_w_state,GNIS_Name) %>%
    summarize(geometry = st_union(Shape)) %>% 
    ungroup()
  
  ## Handling Lake Winnemucca which does not exist in nhd hr
  Winnemucca <- get_waterbodies(AOI = st_sfc(lakes$point_geometry[lakes$lake =='Winnemucca Lake'],
                                             crs = selected_crs))
  
  ## Handling Owen's lake which does not exist in nhd hr
  Owen <- get_waterbodies(AOI = st_sfc(lakes$point_geometry[lakes$lake == 'Owens Lake'], 
                                       crs = selected_crs))
  
  ## Handling Warner lakes/wetlands which is made u of collection of shallow wetland lakes. Full list taken from https://www.blm.gov/visit/warner-wetlands
  Warner_lakes <- c('Pelican Lake',
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
  
  Warner <-  nhd_hr$NHDWaterbody %>% 
    filter(GNIS_Name %in% Warner_lakes,
           Permanent_Identifier != wrong_swamp_lake_id) %>% 
    st_zm() %>% 
    st_make_valid() %>%
    st_transform(crs = st_crs(lakes)) %>% 
    st_join(x = ., y = states) %>% 
    mutate(lake_w_state = paste('Warner Lake', STATE_ABBR, sep = ',')) %>% 
    filter(lake_w_state %in% lakes$lake_w_state) 
  
  Warner_lakes <- Warner %>%
    group_by(lake_w_state) %>%
    summarize(geometry = st_union(Shape)) %>% 
    ungroup()
  
  lakes_map <- lakes_nhdhr %>% 
    add_row(lake_w_state = 'Winnemucca Lake,NV',
            GNIS_Name = 'Winnemucca Lake',
            geometry = Winnemucca$geometry[1]) %>%
    filter(GNIS_Name != 'Warner Lake') %>% 
    add_row(lake_w_state = Warner_lakes$lake_w_state[1],
            GNIS_Name = 'Warner Lakes',
            geometry = Warner_lakes$geometry[1]) %>%
    add_row(lake_w_state = 'Owens Lake,CA',
            GNIS_Name = 'Owens Lake',
            geometry = Owen$geometry[1]) %>%
    mutate(X = st_coordinates(st_centroid(geometry))[,1],
           Y = st_coordinates(st_centroid(geometry))[,2]) %>% 
    mutate(flag = ifelse(GNIS_Name == 'Winnemucca Lake','nhd',
                         ifelse(GNIS_Name == 'Warner Lakes',
                                'From nhd hr. The Warner Lakes (aka Warner Wetlands) consist of 12 shallow lakes in South East Oregon, and include Pelican, Crump, Hart Lakes, among others', 'From nhd hr')))
  
  return(lakes_map)
  
}

#process_saline_lakes_sf(nhdhr_lakes_path = p1_download_nhdhr_lakes_backup_download_path, lakes_sf = lakes, states_sf = states)
