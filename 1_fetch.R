source("1_fetch/src/Download_nhd.R")

p1_targets_list <- list(
  
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
