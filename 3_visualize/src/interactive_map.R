# Build interactive map with leaflet
build_map_leaflet <- function(p3_huc8_sf, p3_saline_lakes_sf, p3_flowlines_sf, p3_gage_sites_sf){
  # Define color ramp for steams
  pal_stream <- colorFactor(
    palette = scico::scico(9, palette = 'davos')[6:3],
    domain = p3_flowlines_sf$streamorde_size)
  
  # Define color ramp for gages
  pal_gage <- colorFactor(
    palette = scico::scico(16, palette = 'davos')[c(11, 1)],
    domain = p3_gage_sites_sf$in_HUC8)
  
  # Build map
  leaflet() %>% 
    #Add Basemap
    addProviderTiles("Esri.WorldGrayCanvas", group = c("No labels", "Labels"))  %>%
    addProviderTiles("CartoDB.PositronOnlyLabels", group = "Labels") %>%
    
    # Add data layers
    addPolygons(data = p3_huc8_sf, group = "Subbasin (HUC 8)",
                color = "#C3CB9F", opacity = 0.4, weight = 3,
                popup = ~label) %>% 
    addPolygons(data = p3_saline_lakes_sf, group = "Saline lakes",
                color = '#3A6DB7', opacity = 0.8, weight = 2,
                popup = ~label) %>%
    addPolylines(data = p3_flowlines_sf, group = "Streams",
                 color = ~pal_stream(streamorde), opacity = 0.8,
                 weight = ~streamorde,
                 popup = ~label) %>%
    addCircleMarkers(data = p3_gage_sites_sf, group = "Gage sites",
                     color = ~pal_gage(in_HUC8), radius = 5, weight = 2,
                     popup = ~label) %>%
    addLabelOnlyMarkers(data = p3_saline_lakes_sf, lng = ~X, lat = ~Y, group = "Lake labels",
               label = ~lake_w_state,
               labelOptions = labelOptions(noHide = T, textOnly = T)) %>%
    
    # Add legend
    addLegend(data = p3_flowlines_sf, group = "Streams",
              title = "Stream order",
              pal = pal_stream, values = ~streamorde_size,
              position = "bottomright") %>%
    
    addLegend(data = p3_gage_sites_sf, group = "Gage sites",
              title = "Within saline lake subbasin",
              pal = pal_gage, values = ~in_HUC8,
              position = "bottomright") %>%
    
    # Add layer controls
    addLayersControl(baseGroups = c("Labels", "No Labels"),
                     overlayGroups = c("Saline lakes", "Lake labels", "Subbasin (HUC 8)", "Streams", "Gage sites"),
                     position = "topright",
                     options = layersControlOptions(collapsed = F)) %>%
    hideGroup(c("Streams", "Gage sites"))
}


