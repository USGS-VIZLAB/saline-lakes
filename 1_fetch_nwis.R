

p1_nw_targets_list <- list(
  
  # Fetch NWIS sites along tributaries and in our huc08 regions 
  ## NOTE - this is fetching nwis sites from the nhdplusTools package. In separate branch these sites are queries directly from dataRetrieval - output can then compare
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
  )


)
