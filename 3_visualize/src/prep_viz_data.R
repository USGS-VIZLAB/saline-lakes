# Create HUC-Lake crosswalk
assc_lakes_xwalk_df <- function(huc_sf, huc_column = 'HUC8'){
  
  huc_sf %>%
    st_drop_geometry() %>%
    distinct(.data[[huc_column]], lake_w_state, .keep_all = F) %>%
    group_by(.data[[huc_column]]) %>%
    summarise(assc_lakes = paste(lake_w_state, collapse =  "; "))
}

prep_huc_viz_sf <- function(huc_sf, selected_huc_col){
    new_huc_sf <- huc_sf %>% 
      mutate(ID_Name = paste0(.data[[selected_huc_col]],': ',Name)) %>%
      ms_simplify()
  
    return(new_huc_sf)
}

# Prep saline lake data for leaflet map
prep_lakes_viz_sf <- function(lakes_sf, crs_plot){

  lakes_sf %>%
    mutate(state = str_sub(lake_w_state, -2)) %>%
    mutate(label = str_c("Lake: ", str_sub(lake_w_state, 1, -3), " ", str_sub(lake_w_state, -2))) %>%
    st_as_sf() %>%
    st_transform(crs = crs_plot)
    
}

# # Prep HUC data for leaflet map
# prep_huc_viz_sf <- function(huc_sf, assc_lakes_df, crs_plot, huc_column = 'HUC8'){
#   huc_sf %>%
#     distinct({{huc_column}}, lake_w_state, .keep_all = T) %>%
#     left_join(assc_lakes_df, by = huc_column) %>%
#     mutate(label = paste0("HUC",gsub(huc_column,'HUC',''),": ",
#                           Name, "(", {{huc_column}}, ")",
#                           "<br>", "Associated lake: ", assc_lakes)) %>%
#     st_as_sf() %>%
#     st_transform(crs = crs_plot)
# }

# Prep stream data for leaflet map
prep_flowlines_viz_sf <- function(flowlines_sf, crs_plot){

  flowlines_sf %>%
    rmapshaper::ms_simplify() %>%
    mutate(label = paste0("Stream: ",
                          ifelse(gnis_name == " ", "No GNIS name/ID",
                                 paste0(gnis_name, " (", gnis_id, ")")),
                          " <br> Stream order ", streamorde)) %>%
    st_as_sf() %>%
    st_transform(crs = crs_plot)
}

# Prep gage site data within watersheds for output map 

prep_gage_viz_sf <- function(watershed_sf, nwis_sites_df, selected_service){
  watershed_sf %>%
    filter(site_no %in% unique( nwis_sites_df$site_no)) %>% 
    mutate(service = selected_service,
           label = paste(site_no,': ', station_nm))
  
}