# Prep saline lake data for leaflet map
prep_lakes_viz_sf <- function(lakes_sf, crs_plot){
  lakes_sf %>%
    mutate(state = str_sub(lake_w_state, -2)) %>%
    mutate(label = str_c("Lake: ", str_sub(lake_w_state, 1, -3), " ", str_sub(lake_w_state, -2))) %>%
    st_as_sf() %>%
    st_transform(crs = crs_plot)
}

# Prep HUC8 watershed data for leaflet map
prep_huc8_viz_sf <- function(huc8_sf, crs_plot){
  huc8_sf %>%
    mutate(duplicate = duplicated(TNMID)) %>%
    filter(duplicate == F) %>%
    mutate(label = paste0("HUC8: ", Name, "(", HUC8, ")")) %>%
    st_as_sf() %>%
    st_transform(crs = crs_plot)
}

