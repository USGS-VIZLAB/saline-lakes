source("1_fetch/src/Download_nhd.R")
source('1_fetch/src/download_states_shp.R')
source('1_fetch/src/fetch_by_site_and_service.R')
source('1_fetch/src/get_NWIS_site_no.R')

p1_targets_list <- list(
  
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
             lake_w_state = paste(lake,state_abbr, sep = ','),
             lake_name_shrt = trimws(str_replace(lake, pattern = 'Lake', replacement = "")))
    }
      ),
  
  # Download states shp
  tar_target(
    p1_download_states_shp,
    download_states_shp(url = pO_states_dwnld_url, 
                        out_path = '1_fetch/in/states_shp'),
    format = 'file'
  ),
  
  tar_target(
    p1_states_sf,
    st_read(file.path(p1_download_states_shp,'statesp010g.shp'), quiet = TRUE) %>%
      filter(STATE_ABBR %in% c('CA',"NV",'UT','OR')) %>% 
      st_transform(crs = st_crs(p1_lakes_sf)) %>% 
      select(NAME,STATE_ABBR, geometry)
  ),
  
  # 1st fetch of huc08 to get high res nhd data (water bodies, huc8 areas) for focal laakes
  tar_target(
    p1_huc08_df,
    get_huc8(AOI = p1_lakes_sf$point_geometry)
  ),

  # Split huc ids to 04 to pull nhdhr
  tar_target(
    p1_huc04_for_download,
    substr(p1_huc08_df$huc8, start = 1, stop = 4) %>% unique()
  ),
  
# Download high res nhd data to get lake water bodies #
  ## 2 OPTIONS - 1) try downloading by running the `p1_download_nhdhr_lakes_path` target below with download_nhdplushr() from the nhdplusTools R package. 
  ## 2) If timeout error occurs with 1), manually copy (scp) to local from designated hpc location in caldera . See instructions above target.
  
  # 1) Downloading nhd hr for our AOI at huc04 level, (placing in 1_fetch/in/ folder for now)
  #### tbd - Check if targets::tar_files() works better here for downloading targets of file format

   tar_target(
    p1_download_nhdhr_lakes_path,
    {download_nhdplushr('1_fetch/in/nhdhr', p1_huc04_for_download)},
    pattern = map(p1_huc04_for_download),
    format = 'file'
   ),

  # 2) Using backup path via tallgrass. Log into tallgrass and navigate to the saline lakes nhdhr data folder
  ## This lives in caldera/projects/usgs/water/iidd/datasci/data-pulls/nhdplushr-salinelakes-msleckman/nhdplusdata
  ## run a scp on all subfolders in  /nhdplusdata/ and place them in the newly created local folder `1_fetch/in/nhdhr_backup` (created w/ dir.create() in _targets.R)

  # tar_target(p1_download_nhdhr_lakes_path,
  #          '1_fetch/in/nhdhr_backup'
  # ),
  
  # Fetch water bodies - HR
  tar_target(p1_nhdhr_lakes, 
              get_nhdplushr(hr_dir = p1_download_nhdhr_lakes_path,
                            layer= 'NHDWaterbody')$NHDWaterbody
  ),

  # Fetch watershed boundary areas filtered to our lakes - huc12 - HR
  ## note possible duplicate polygons since some individual saline lakes have same huc08 
  tar_target(
    p1_get_lakes_huc12_sf,
    get_nhdplushr(hr_dir = p1_download_nhdhr_lakes_path,
                  layer= 'WBDHU12')$WBDHU12 %>% 
      ## filter to lakes HUC12
      st_transform(crs = st_crs(p2_saline_lakes_sf)) %>% st_join(p2_saline_lakes_sf) %>% filter(!is.na(GNIS_Name))
    ),

  # Fetch watershed boundary areas - huc08  
  ## note possible duplicate polygons since some individual saline lakes have same huc08 
  tar_target(
    p1_get_lakes_huc8_sf,
    get_nhdplushr(hr_dir = p1_download_nhdhr_lakes_path,
                  layer= 'WBDHU8')$WBDHU8 %>% 
      ## filter to lakes HUC8 - (can move to process)
      st_transform(crs = st_crs(p2_saline_lakes_sf)) %>% st_join(p2_saline_lakes_sf) %>%
      filter(!is.na(GNIS_Name))
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
  
  # Fetch NWIS sites along tributaries and in our huc08 regions. 
  ## Will require further filtering (e.g. ftype == ST, along flowlines only)
  tar_target(
    p1_nwis_sites,
    {tryCatch(expr = get_huc8(id = p1_huc8_vec) %>% get_nwis(AOI = .) %>%
                ## making as dataframe to load with tar_load()
                as.data.frame() %>% 
                mutate(HUC8 = p1_huc8_vec),
              error = function(e){
                return(warning(e$message))
                },
              warning = function(w){
                return(message(paste(w$message, 'huc8:', p1_huc8_vec)))
              }
              )},
  pattern = map(p1_huc8_vec)
  ),

  # Pulling site data retrieval using whatNWISsites(). This target is a sf object can be joined to nwis datasets below via site_no 
  ## subsetting huc8 multipolygon to simplify join in get_NWIS_site_no() 
  tar_target(
    p1_site_in_watersheds_sf,
    get_NWIS_site_no(basin_huc08 = p1_huc08_df$huc8,
                     lake_watershed_sf = p1_get_lakes_huc8_sf %>% select(HUC8, Shape), 
                     crs = selected_crs)
    ),

  tar_target(
    p1_site_no,
    {p1_site_in_watersheds_sf %>% pull(site_no)}
  ),

  ###################
  # NWIS Data Queries
  
  # SW
  ## SW - dv
  tar_target(
    p1_nwis_dv_sw_data,
    fetch_by_site_and_service(sites = p1_site_no,
                              pcodes = p0_sw_params,
                              service = 'dv',
                              start_date = p0_start,
                              end_date = p0_end)
    ),

  ## SW - iv
  ## dv data is summarized from iv data, therefore any site with dv data will have iv data and vis versa
  ## iv data is much heavier so we provided a filtered list to lighten the load of request
  tar_target(
    p1_nwis_iv_sw_data,
    fetch_by_site_and_service(sites = unique(p1_nwis_dv_sw_data$site_no),
                              pcodes = p0_sw_params,
                              service = 'iv',
                              start_date = p0_start,
                              end_date = p0_end,
                              incrementally = TRUE,
                              split_num = 10)
    ),

  ## SW - field measurements
  tar_target(
    p1_nwis_meas_sw_data,
    fetch_by_site_and_service(sites = p1_site_no,
                              ## note - for service = measurements, pcodes is irrelevant
                              pcodes = p0_sw_params,
                              service = 'measurements',
                              start_date = p0_start,
                              end_date = p0_end)
  ),

  # GW
  ## GW - dv
  tar_target(
    p1_nwis_dv_gw_data,
    fetch_by_site_and_service(sites = p1_site_no,
                              pcodes = p0_gw_pcodes,
                              service = 'dv',
                              start_date = p0_start,
                              end_date = p0_end)
  ),
  
  ## GW - iv
  ## dv data is summarized from iv data, therefore any site with dv data will have iv data and vis versa
  ## iv data is much heavier so we provided a filtered list to lighten the load of request
  tar_target(
    p1_nwis_iv_gw_data,
    fetch_by_site_and_service(sites = unique(p1_nwis_dv_gw_data$site_no),
                              pcodes = p0_gw_pcodes,
                              service = 'iv',
                              start_date = p0_start,
                              end_date = p0_end)
  ),
  
  tar_target(
    p1_nwis_meas_gw_data,
    fetch_by_site_and_service(sites = p1_site_no,
                              pcodes = p0_gw_pcodes,
                              service = 'gwlevels',
                              start_date = p0_start,
                              end_date = p0_end)
  )
)