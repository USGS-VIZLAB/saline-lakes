source("1_fetch/src/Download_nhd.R")

p1_targets_list <- list(
  
  ## Read list of lakes
  tar_target(
    p1_lakes_df,
    readxl::read_xlsx('1_fetch/in/Lakes_list.xlsx', col_types = 'text') %>% 
      st_as_sf(coords = c('Lon','Lat'), crs = 4326) %>% 
      rename(Point_geometry = geometry, lake = `Lake Ecosystem`) %>% 
      mutate(State_abbr = case_when(State == 'California' ~ 'CA',
                                    State == 'Nevada' ~ 'NV',
                                    State == 'Utah' ~ 'UT',
                                    State == 'Oregon' ~ 'OR',
                                    State == 'California/Oregon' ~ 'CA', # Put lake crossing OR CA border as CA for now.  
                                    TRUE ~ 'NA'),
             lake = str_to_title(lake),
             lake_w_state = paste(lake,State_abbr, sep = ','),
             lake_name_shrt = trimws(str_replace(lake, pattern = 'Lake', replacement = "")))
  ),
  
  ## States
  ## no sbtools access to this link - manually download and from  
  ## https://www.sciencebase.gov/catalog/item/581d052de4b08da350d524e5
  ## place final shp files in states_shp folder then this will work
  tar_target(
    p1_states_sf,
    st_read('1_fetch/in/states_shp/statesp010g.shp', quiet = TRUE) %>%
      filter(STATE_ABBR %in% c('CA',"NV",'UT','OR')) %>% 
      st_transform(crs = st_crs(p1_lakes_df)) %>% 
      select(NAME,STATE_ABBR, geometry)
  ),
  
  ## Get huc08 for focal lakes - might not be necessary if we have nhdhr water bodies already downloaded
  tar_target(
    p1_huc08_df,
    get_huc8(AOI = p1_lakes_df$Point_geometry)
  ),

  tar_target(
    p1_huc04_for_download,
    substr(p1_huc08_df$huc8, start = 1, stop = 4) %>% unique()
  ),
  
  ## downloading to the in folder for now - will move to out
  tar_target(
    p1_download_nhdhr_lakes,
    nhdplusTools::download_nhdplushr('1_fetch/in/nhdhr/', p1_huc04_for_download),
    pattern = map(p1_huc04_for_download)
  )
  
)