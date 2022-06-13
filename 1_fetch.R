source("1_fetch/src/Download_nhd.R")

p1_targets_list <- list(
  
  ## List of lakes
  tar_target(lakes,
             readxl::read_xlsx('Data/Lakes_list.xlsx',
                               col_types = 'text') %>% 
               st_as_sf(coords = c('Lon','Lat'), crs = 4326) %>% 
               rename(Point_geometry = geometry, lake = `Lake Ecosystem`) %>% 
               mutate(State_abbr = case_when(State == 'California' ~ 'CA',
                                             State == 'Nevada' ~ 'NV',
                                             State == 'Utah' ~ 'UT',
                                             State == 'Oregon' ~ 'OR',
                                             State == 'California/Oregon' ~ 'CA',
                                             TRUE ~ 'NA'),
                      lake = str_to_title(lake),
                      lake_w_state = paste(lake,State_abbr, sep = ','),
                      lake_name_shrt = trimws(str_replace(lake,
                                                          pattern = 'Lake',
                                                          replacement = "")))
             ),
  
  ## States
  tar_target(
    st_read('in/statesp010g.shp_nt00938/statesp010g.shp') %>%
      filter(STATE_ABBR %in% c('CA',"NV",'UT','OR')) %>% 
      st_transform(crs = st_crs(lakes)) %>% 
      select(NAME,STATE_ABBR, geometry)
  ),
  
  ## Get huc08 for focal lakes - might not be necessary if we have nhdhr water bodies already downloaded
  tar_target(
    huc08_df,
    get_huc8(AOI = lakes$Point_geometry)),

    tar_target(huc04_comids_for_download,
             substr(huc08_df$huc8, start = 1, stop = 4) %>% unique())
  

  
  

)