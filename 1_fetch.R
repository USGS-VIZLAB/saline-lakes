source("1_fetch/src/Download_nhd.R")
source('2_process/src/process_saline_lakes_sf.R')

p1_targets_list <- list(
  
  ## Read list of lakes
  tar_target(
    p1_lakes_sf,
    read_csv('1_fetch/in/saline_lakes.csv', col_types = 'ccnn') %>% 
      st_as_sf(coords = c('Lon','Lat'), crs = 4326) %>% 
      rename(point_geometry = geometry, lake = `Lake Ecosystem`, state = State) %>% 
      mutate(state_abbr = case_when(state == 'California' ~ 'CA',
                                    state == 'Nevada' ~ 'NV',
                                    state == 'Utah' ~ 'UT',
                                    state == 'Oregon' ~ 'OR',
                                    state == 'California/Oregon' ~ 'CA', # Put lake crossing OR CA border as CA for now.  
                                    TRUE ~ 'NA'),
             lake = str_to_title(lake),
             lake_w_state = paste(lake,state_abbr, sep = ','),
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
      st_transform(crs = st_crs(p1_lakes_sf)) %>% 
      select(NAME,STATE_ABBR, geometry)
  ),
  
  ## Get huc08 for focal lakes - might not be necessary if we have nhdhr water bodies already downloaded
  tar_target(
    p1_huc08_df,
    get_huc8(AOI = p1_lakes_sf$point_geometry)
  ),

  tar_target(
    p1_huc04_for_download,
    substr(p1_huc08_df$huc8, start = 1, stop = 4) %>% unique()
  ),
  
  ## downloading to the in folder for now
  # tar_target(
  #   p1_download_nhdhr_lakes,
  #   nhdplusTools::download_nhdplushr('1_fetch/in/nhdhr/', p1_huc04_for_download),
  #   format = 'file',
  #   pattern = map(p1_huc04_for_download_fltrd),
  # ),
  
  tar_target(
    p1_saline_lakes_sf,
    process_saline_lakes_sf(nhdhr_lakes_path = p1_download_nhdhr_lakes_backup_download_path,
                            lakes_sf = p1_lakes_sf,
                            states_sf = p1_states_sf,
                            selected_crs = selected_crs)
    ),
  
  ## get watershed boundary areas 
  tar_target(
    p1_get_lakes_huc12_sf,
    {get_huc12(AOI = p1_saline_lakes_sf, buffer = 1) %>%
      select(id, huc12, name, states, geometry)}
    ),
    
  tar_target(
    p1_get_lakes_huc8_sf,
    {get_huc8(AOI = p1_saline_lakes_sf, buffer = 1) %>%
      select(id, huc8, name, states, geometry)}
    ),

  ## get nwis sites 
  tar_target(
    p1_huc8_vec, 
    {unique(p1_get_lakes_huc8_sf$huc8)}
  ),

  ## Fetch nhdplus flowlines for each huc8 region separately through dynamic branching - fixing lakefract type difference between branches 
  tar_target(
    p1_lake_flowlines_huc8_sf,
    get_nhdplus(AOI = p1_get_lakes_huc8_sf %>%
                  filter(huc8 == p1_huc8_vec),
                realization = 'flowline') %>% mutate(lakefract = as.character(lakefract)), 
    pattern = map(p1_huc8_vec)
  )
)

