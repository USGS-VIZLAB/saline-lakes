source("1_fetch/src/Download_nhd.R")
source('1_fetch/src/download_states_shp.R')
source('1_fetch/src/fetch_nhdplus_data.R')

p1_targets_list <- list(
  
  ## Lake sf dataset from Sharepoint - stakeholder provided
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
                                     out_gpkg_path = '1_fetch/in/nhd_WB_HU8_HU10.gpkg',
                                     layer = c('NHDWaterbody','WBDHU8','WBDHU10')),
             format = 'file'
  ),

  # Read in all waterbodies in full basin
  tar_target(p1_nhdhr_lakes,
              sf::st_read('1_fetch/in/nhd_WB_HU8_HU10.gpkg',
                          layer = 'NHDWaterbody',
                          query = 'SELECT * FROM NHDWaterbody WHERE Shape_Area > 7e-08',
                          quiet = TRUE)),

  # Fetch watershed boundary areas filtered to our lakes - huc8 - HR
  ## note possible duplicate polygons since some individual saline lakes have same huc08 
  tar_target(
    p1_get_lakes_huc8_sf,
    st_read(p1_nhd_gpkg, layer = 'WBDHU8', quiet = TRUE) %>% 
      ## filter to lakes HUC12
      st_transform(crs = st_crs(p2_saline_lakes_sf)) %>%
      st_join(p2_saline_lakes_sf) %>% filter(!is.na(GNIS_Name)) %>% 
      distinct()
    ),

  # Fetch watershed boundary areas - huc10  
  ## note possible duplicate polygons since some individual saline lakes have same huc10 
  ## Thsi target is very slow to build! 
  tar_target(
    p1_get_lakes_huc10_sf,
    st_read(p1_nhd_gpkg, layer = 'WBDHU10', quiet = TRUE) %>% 
      ## Filtering huc10 to within huc8 - (can move to process)
      st_transform(crs = st_crs(p1_get_lakes_huc8_sf)) %>%
      st_join(x = ., y = p1_get_lakes_huc8_sf[,c('HUC8','lake_w_state')]) %>%
      filter(!is.na(HUC8)) %>% 
      distinct()
    ),

  # Grab vector of our huc08s in order to run branching for nhd flowlines fetch  
  tar_target(
    p1_huc8_vec, 
    {unique(p1_get_lakes_huc8_sf$HUC8)}
  ),

  # Fetch nhdplus flowlines for each huc8 region separately through dynamic branching - note difference between branches 
  tar_target(
    p1_lake_flowlines_huc8_sf,
    {get_nhdplus(AOI = {p1_get_lakes_huc8_sf %>% filter(HUC8 == p1_huc8_vec)},
                 realization = 'flowline') %>%
        ## making as dataframe to load with tar_load()
        #as.data.frame() %>% 
        ## fixing col that are automatically transforming to char
        mutate(across(c(surfarea, lakefract, rareahload), ~as.numeric(.x)),
               HUC8 = p1_huc8_vec) 
        ## filtering out flowlines w/ vals below 1 (can be move to process)
    #    filter(streamorde >= 3)
      }, 
    pattern = map(p1_huc8_vec)
  ),
  
  # Fetch NWIS sites along tributaries and in our huc08 regions 
  ## Will require further filtering (e.g. ftype == ST, along flowlines only)
  tar_target(
    p1_nwis_sites,
    {tryCatch(expr = get_huc8(id = p1_huc8_vec) %>% get_nwis(AOI = .) %>%
                ## making as dataframe to load with tar_load()
                #as.data.frame() %>% 
                mutate(HUC8 = p1_huc8_vec),
              error = function(e){message(paste('error - No gages found in huc8', p1_huc8_vec))})},
  pattern = map(p1_huc8_vec)
  ),

  ## Pulling site no from gauge sites to then query nwis and WQP with data retrieval
  tar_target(
    p1_site_ids,
    {p1_nwis_sites %>% pull(site_no) %>% unique()}
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