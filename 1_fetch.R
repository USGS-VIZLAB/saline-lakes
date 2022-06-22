source("1_fetch/src/Download_nhd.R")
## process_saline_lakes_sf.R should ultimately move to /1_fetch/. OR target built by this function should be moved to 2_process.R
source('2_process/src/process_saline_lakes_sf.R')

p1_targets_list <- list(
  
  ## Reading and cleaning list of saline lakes
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
  
  ## States
  ## no sbtools access to this link https://www.sciencebase.gov/catalog/item/581d052de4b08da350d524e5
  ## chose to keep in remote repo
  ## Can also manually download from  
  ## place final shp files in states_shp folder then this will work
  tar_target(
    p1_states_sf,
    st_read('1_fetch/in/states_shp/statesp010g.shp', quiet = TRUE) %>%
      filter(STATE_ABBR %in% c('CA',"NV",'UT','OR')) %>% 
      st_transform(crs = st_crs(p1_lakes_sf)) %>% 
      select(NAME,STATE_ABBR, geometry)
  ),
  
  ## Fetch huc08 for focal lakes - (not be necessary if we have nhdhr water bodies manually downloaded
  tar_target(
    p1_huc08_df,
    get_huc8(AOI = p1_lakes_sf$point_geometry)
  ),

  ## 
  tar_target(
    p1_huc04_for_download,
    substr(p1_huc08_df$huc8, start = 1, stop = 4) %>% unique()
  ),
  
  ## Download high res nhd data to get lake water bodies 
  ## 2 OPTIONS - 1) try downloading with download_nhdplushr() from nhdplusTools R package. 
  ## 2) If you get timeout errors with 1), manually copy (scp) to local from designated hpc location in caldera . See instructions above target 
  
  ## 1) Downloading nhd hr for our AOI at huc04 level, (placing in 1_fetch/in/ folder for now
  ## Note - Check if targets::tar_files() works better here for downloading targets of file format
  
#   tar_target(
#     p1_download_nhdhr_lakes_path,
#     download_nhdplushr('1_fetch/in/nhdhr/', p1_huc04_for_download),
#     pattern = map(p1_huc04_for_download)
#   # format file
# #    format = 'file',
#   ),
  
  ## 2) Using backup path via tallgrass. Log into tallgrass and navigate saline lakes nhdhr data folder for saline lakes to get datat
  ## This lives in caldera/projects/usgs/water/iidd/datasci/data-pulls/nhdplushr-salinelakes-msleckman/nhdplusdata
  ## run a scp of all subfolders in  /nhdplusdata/ and place them in the newly created folder `1_fetch/in/nhdhr_backup` (created w/ dir.create() in _targets.R)
    tar_target(p1_download_nhdhr_lakes_backup_path,
             '1_fetch/in/nhdhr_backup'
             ),
  


  ## Fetch and Process saline lakes via specifically built function that creates the final saline lakes shapefile 
  ## This fun not yet generalized, special handling of lakes included in fun
  ## NOTE - Change nhdhr_lakes_path param with either p1_download_nhdhr_lakes_path or p1_download_nhdhr_lakes_backup_path depending on where nhdhr lives
  
  tar_target(
    p1_saline_lakes_sf,
    process_saline_lakes_sf(nhdhr_lakes_path = p1_download_nhdhr_lakes_backup_path,
                            lakes_sf = p1_lakes_sf,
                            states_sf = p1_states_sf,
                            selected_crs = selected_crs)
    ),
  
  ## Fetch watershed boundary areas - huc12
  tar_target(
    p1_get_lakes_huc12_sf,
    {get_huc12(AOI = p1_saline_lakes_sf, buffer = 1) %>%
      select(id, huc12, name, states, geometry)}
    ),

  ## Fetch watershed boundary areas - huc08  
  tar_target(
    p1_get_lakes_huc8_sf,
    {get_huc8(AOI = p1_saline_lakes_sf, buffer = 1) %>%
      select(id, huc8, name, states, geometry)}
    ),

  ## Grab vector of our huc08s to run branching for flowline fetch  
  tar_target(
    p1_huc8_vec, 
    {unique(p1_get_lakes_huc8_sf$huc8)}
  ),

  ## Fetch nhdplus flowlines for each huc8 region separately through dynamic branching - note difference between branches 
  tar_target(
    p1_lake_flowlines_huc8_sf,
    get_nhdplus(AOI = p1_get_lakes_huc8_sf %>%
                  filter(huc8 == p1_huc8_vec),
                realization = 'flowline'), 
    pattern = map(p1_huc8_vec)
  )
  
  ## Fetch nwis sites along tributaries and in our huc08 regions. Requires further filtering (e.g. ftype == ST, along flowlines only)
  # tar_target(
  #   p1_nwis_sites,
  #   get_nwis(AOI = p1_get_lakes_huc8_sf)
  # )
  
)

