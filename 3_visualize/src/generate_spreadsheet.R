build_feedback_spreadsheet <- function(p1_get_lakes_huc8_sf, out_file){
  out <- p1_get_lakes_huc8_sf %>%
    st_drop_geometry() %>%
    as.data.frame() %>%
    distinct() %>%
    select(lake_w_state, Name, HUC8) %>%
    arrange(lake_w_state, HUC8) %>%
    rename(`Saline lake` = lake_w_state, 
           `Subbasin name` = Name) %>%
    mutate(`Keep/discard` = "",
           Notes = "") 
  
  wb <- createWorkbook()
  addWorksheet(wb, "Subbasins")
  writeDataTable(wb, 1, out, tableStyle = "TableStyleLight9")
  setColWidths(wb, 1, cols = 1:4, widths = "auto")
  setColWidths(wb, 1, cols = 5, widths = 20)
  saveWorkbook(wb, out_file, overwrite = T)
  
  return(out_file)
}

