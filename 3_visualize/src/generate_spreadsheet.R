build_feedback_spreadsheet <- function(p1_get_lakes_huc8_sf, p3_flowlines_sf, assc_lakes_df, out_file){
  # Build table for subbasins
  subbasins <- p1_get_lakes_huc8_sf %>%
    st_drop_geometry() %>%
    as.data.frame() %>%
    distinct() %>%
    select(lake_w_state, Name, HUC8) %>%
    arrange(lake_w_state, HUC8) %>%
    rename(`Saline lake` = lake_w_state, 
           `Subbasin name` = Name) %>%
    mutate(`Keep/discard` = "",
           Notes = "") 
  
  # Build table for streams
  flowlines <- p3_flowlines_sf %>%
    st_drop_geometry() %>%
    as.data.frame() %>%
    filter(gnis_id != " ") %>%
    select(HUC8, gnis_name, gnis_id) %>%
    distinct(.keep_all = T) %>%
    left_join(assc_lakes_df, by = "HUC8") %>%
    relocate(assc_lakes) %>%
    arrange(assc_lakes, HUC8, gnis_name, gnis_id) %>%
    rename(`Associated lakes` = assc_lakes, 
           `Stream name` = gnis_name,
           `GNIS ID` = gnis_id) %>%
    mutate(`Keep/discard` = "",
           Notes = "") 
  
  # Create Excel workbook for export
  wb <- createWorkbook()
  
  # Add and format subbasin worksheet
  addWorksheet(wb, "Subbasins")
  writeDataTable(wb, 1, subbasins, tableStyle = "TableStyleLight9")
  setColWidths(wb, 1, cols = 1:4, widths = "auto")
  setColWidths(wb, 1, cols = 5, widths = 20)
  
  # Add and format flowlines worksheet
  addWorksheet(wb, "Streams")
  writeDataTable(wb, 2, flowlines, tableStyle = "TableStyleLight9")
  setColWidths(wb, 2, cols = 1:5, widths = "auto")
  setColWidths(wb, 2, cols = 6, widths = 20)
  
  
  # Export workbook
  saveWorkbook(wb, out_file, overwrite = T)
  
  return(out_file)
}

