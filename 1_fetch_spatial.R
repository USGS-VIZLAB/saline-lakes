source("1_fetch/src/Download_nhd.R")
source('1_fetch/src/download_states_shp.R')
source('1_fetch/src/fetch_nhdplus_data.R')

p1_sp_targets_list <- list(
  
  ## Lake sf dataset from sharepoint - stakeholder provided
  ## This target is the same as p2_saline_lakes_sf but includes the manually drawn polygon Carson Sink.
  ## This target is created to 1/ have a second multipolygon dataset for lakes 2/ append 
  ## This should be manually downloaded to local 1_fetch/in/ folder 
  tar_target(
    p1_saline_lakes_bnds_sf,
    st_read('1_fetch/in/SalineLakeBnds.shp') %>% 
      st_transform(crs=st_crs(p1_lakes_sf)) %>% 
      ## Formatting for easier rbind with p2_saline_lakes_sf
      rename(GNIS_Name = Name) %>% 
      mutate(lake_w_state = paste0(GNIS_Name,',',State)) %>% 
      select(lake_w_state, GNIS_Name, geometry)
  ),
  
  # Reading and cleaning list of saline lakes
  tar_target(
    p1_lakes_sf,
    {read_csv('1_fetch/in/saline_lakes.csv', col_types = 'ccnn') %>% 
        st_as_sf(coords = c('Lon','Lat'), crs = selected_crs) %>% 
        rename(point_geometry = geometry, lake = `Lake Ecosystem`, state = State) %>% 
        mutate(state_abbr = case_when(state == 'California' ~ 'CA',
                                      state == 'Nevada' ~ 'NV',
                                      state == 'Utah' ~ 'UT',
                                      state == 'Oregon' ~ 'OR',
                                      state == 'California/Oregon' ~ 'CA', # Put lake crossing OR CA border as CA for now.  
                                      TRUE ~ 'NA'),
               lake = str_to_title(lake),
               lake_w_state = paste(lake, state_abbr, sep = ','),
               lake_name_shrt = trimws(str_replace(lake, pattern = 'Lake', replacement = "")))
    }
  ),
  
  # 1st fetch of huc08  to get high res nhd data (water bodies, huc8 areas) for focal lakes
  tar_target(
    p1_huc08_full_basin_sf,
    get_huc8(AOI = p1_lakes_sf$point_geometry)
  ),
  
  # Split huc ids to 04 to pull nhdhr
  tar_target(
    p1_huc04_for_download,
    substr(p1_huc08_full_basin_sf$huc8, start = 1, stop = 4) %>%
        unique() %>%
        ## adding 1601 which is a HU4 that contains watersheds relevant to Great Salt Lake 
        append('1601')
  ),
  
  # Download high res nhd data to get lake water bodies #
  
  tar_target(
    p1_download_nhdhr_lakes_path,
    download_nhdhr_data(nhdhr_gdb_path = '1_fetch/in/nhdhr',
                        huc04_list = p1_huc04_for_download),
    format = 'file'
  ),
  
  # Fetch waterbodies, huc8, huc10 from hr and place in local gpkg
  tar_target(p1_nhd_gpkg, 
             get_downloaded_nhd_data(gdb_path = p1_download_nhdhr_lakes_path,
                                     out_gpkg_path = '1_fetch/in/nhd_WB_HUC6_HU8_HU10.gpkg',
                                     layer = c('NHDWaterbody','WBDHU6', 'WBDHU8', 'WBDHU10')),
             format = 'file'
  ),
  
  # Read in all nhd hr waterbodies in our entire basin
  tar_target(p1_nhdhr_lakes,
             sf::st_read('1_fetch/in/nhd_WB_HUC6_HU8_HU10.gpkg',
                         layer = 'NHDWaterbody',
                         query = 'SELECT * FROM NHDWaterbody WHERE Shape_Area > 7e-08',
                         quiet = TRUE)
  ),
  
  tar_target(
    p1_basin_huc6_sf,
    st_read(p1_nhd_gpkg, layer = 'WBDHU6', quiet = TRUE) %>% 
      st_transform(crs = st_crs(p2_saline_lakes_sf))
  ),
  
  tar_target(
    p1_basin_huc8_sf,
    st_read(p1_nhd_gpkg, layer = 'WBDHU8', quiet = TRUE) %>% 
      st_transform(crs = st_crs(p2_saline_lakes_sf))
  ),
  
  tar_target(
    p1_basin_huc10_sf,
    st_read(p1_nhd_gpkg, layer = 'WBDHU10', quiet = TRUE) %>% 
      st_transform(crs = st_crs(p2_saline_lakes_sf))
  ),
  
  # Fetch watershed boundary areas filtered to our lakes - huc8 - HR
  ## note possible duplicate polygons since some individual saline lakes have same huc08 
  tar_target(
    p1_get_lakes_huc6_sf,
    p1_basin_huc6_sf %>% 
      ## filter HUC6 to only the Huc6 with saline lakes within
      st_join(p2_saline_lakes_sf, left = FALSE) %>%
      filter(!is.na(GNIS_Name)) %>% 
      distinct()
  ),
  
  # Fetch watershed boundary areas filtered to our lakes - huc8 - HR
  ## note possible duplicate polygons since some individual saline lakes have same huc08 
  tar_target(
    p1_get_lakes_huc8_sf,
    p1_basin_huc8_sf %>% 
      ## filter HUC8 to only the HUC8 with within selected HUC6
      st_join(x = ., y = p1_get_lakes_huc6_sf[,c('HUC6','lake_w_state')],
              join = st_within, left = FALSE) %>%
      filter(!is.na(HUC6)) %>% 
      bind_rows(p1_basin_huc8_sf %>% filter(HUC8 %in% additional_GSL_huc8)) %>% 
      distinct()
  ),
  
  # Fetch watershed boundary areas - huc10  
  ## note possible duplicate polygons since some individual saline lakes have same huc10 
  ## This target is very slow to build! 
  tar_target(
    p1_get_lakes_huc10_sf,
    p1_basin_huc10_sf %>%
      ## Filtering HUC10 to within selected HUC8s
      st_join(x = .,
              y = p1_get_lakes_huc8_sf[,c('HUC6', 'HUC8', 'lake_w_state')],
              join = st_within, left = FALSE) %>%
      filter(!is.na(HUC8)) %>% 
      distinct()
  ),
  
  # Grab vector of our huc08s in order to run branching for nhd flowlines fetch  
  tar_target(
    p1_huc8_vec, 
    {unique(p1_get_lakes_huc8_sf$HUC8)}
  ),
  
  # Fetch nhdplus flowlines for each selected huc8 region separately through dynamic branching - note difference between branches 
  tar_target(
    p1_lake_flowlines_huc8_sf,
    {get_nhdplus(AOI = {p1_get_lakes_huc8_sf %>% filter(HUC8 == p1_huc8_vec)},
                 realization = 'flowline') %>%
        ## fixing col that are automatically transforming to char
        mutate(across(c(surfarea, lakefract, rareahload), ~as.numeric(.x)),
               HUC8 = p1_huc8_vec) 
    }, 
    pattern = map(p1_huc8_vec)
  ),
  
  # Download states shp
  tar_target(
    p1_download_states_shp,
    download_states_shp(url = states_download_url, 
                        out_path = '1_fetch/in/states_shp'),
    format = 'file'
  ),
  
  tar_target(
    p1_states_sf,
    st_read(file.path(p1_download_states_shp,'statesp010g.shp'), quiet = TRUE) %>%
      filter(STATE_ABBR %in% c('CA',"NV",'UT','OR')) %>% 
      st_transform(crs = st_crs(p1_lakes_sf)) %>% 
      select(NAME,STATE_ABBR, geometry)
  )
  

)