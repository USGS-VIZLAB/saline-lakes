# Create HUC9-Lake crosswalk
assc_lakes_xwalk_df <- function(huc8_sf){
  huc8_sf %>%
    st_drop_geometry() %>%
    distinct(HUC8, lake_w_state, .keep_all = F) %>%
    group_by(HUC8) %>%
    summarise(assc_lakes = paste(lake_w_state, collapse =  "; "))
}

# Prep saline lake data for leaflet map
prep_lakes_viz_sf <- function(lakes_sf, crs_plot){
  lakes_sf %>%
    mutate(state = str_sub(lake_w_state, -2)) %>%
    mutate(label = str_c("Lake: ", str_sub(lake_w_state, 1, -3), " ", str_sub(lake_w_state, -2))) %>%
    st_as_sf() %>%
    st_transform(crs = crs_plot)
}

# Prep HUC8 data for leaflet map
prep_huc8_viz_sf <- function(huc8_sf, assc_lakes_df, crs_plot){
  huc8_sf %>%
    distinct(HUC8, lake_w_state, .keep_all = T) %>%
    left_join(assc_lakes_df, by = "HUC8") %>%
    mutate(label = paste0("HUC8: ", Name, "(", HUC8, ")", "<br>", "Associated lake: ", assc_lakes)) %>%
    st_as_sf() %>%
    st_transform(crs = crs_plot)
}

# Prep stream data for leaflet map
prep_flowlines_viz_sf <- function(flowlines_sf, crs_plot){
  flowlines_sf %>%
    ms_simplify() %>%
    mutate(streamorde_size = as.factor(as.character(as.numeric(streamorde))),
           streamorde = as.factor(as.character(streamorde)),
           label = paste0("Stream: ", ifelse(gnis_name == " ", "No GNIS name/ID", paste0(gnis_name, " (", gnis_id, ")")), " <br> Stream order ", streamorde)) %>%
    st_as_sf() %>%
    st_transform(crs = crs_plot)
}

# Prep gage site data for leaflet map
prep_gage_viz_sf <- function(nwis_sites, huc8_sf, crs_plot){
  nwis_sites %>%
    left_join(nwis_sites %>%
                st_within(huc8_sf) %>%
                as.data.frame()  %>%
                mutate(site_no = nwis_sites$site_no[row.id],
                       HUC8_within = huc8_sf$HUC8[col.id])  %>%
                select(c(site_no, HUC8_within)) %>%
                distinct(.keep_all = T), 
              by = "site_no") %>%
    mutate(same = HUC8 == HUC8_within,
           in_HUC8 = as.character(!is.na(HUC8_within)),
           label = paste0("Station: ", str_to_title(station_nm), "<br>(", site_no, ")")) %>%
    mutate(in_HUC8 = recode(in_HUC8, "FALSE" = "No", "TRUE" = "Yes")) %>%
    st_as_sf() %>%
    st_transform(crs = crs_plot)
}