build_feedback_spreadsheet <- function(p1_get_lakes_huc8_sf, out_file){
  p1_get_lakes_huc8_sf %>%
    st_drop_geometry() %>%
    as.data.frame() %>%
    distinct() %>%
    select(lake_w_state, Name, HUC8) %>%
    arrange(lake_w_state, HUC8) %>%
    rename(`Saline lake` = lake_w_state, 
           `Subbasin name` = Name) %>%
    mutate(`Keep/discard` = "",
           Notes = "") %>%
    write.xlsx(file = out_file,
               sheetName = "Subbasins",
               col.names = T,
               row.names = F)
  return(out_file)
}

