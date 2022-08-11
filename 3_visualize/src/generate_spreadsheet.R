build_feedback_spreadsheet <- function(p1_get_lakes_huc_sf,
                                       huc_column = 'HUC8',
                                       p3_flowlines_sf,
                                       assc_lakes_df,
                                       out_file,
                                       add_sheet_for_streams = TRUE){

  # Build table for subbasins
  subbasins <- p1_get_lakes_huc_sf %>%
    st_drop_geometry() %>%
    as.data.frame() %>%
    distinct() %>%
    select( lake_w_state, Name,.data[[huc_column]]) %>%
    arrange(lake_w_state, .data[[huc_column]]) %>%
    rename(`Saline lake` = lake_w_state, 
           `Subbasin name` = Name) %>%
    mutate(`Keep/discard` = "",
           Notes = "") 
  
  create_workbook(df_to_export_as_wb = subbasins,
                  worksheet_name = "Subbasins",
                  manual_cols_to_add = NULL, 
                  out_file = out_file, create_wb = TRUE, existing_wb_path = NULL, sheet_num = 1)
  
  ## Optional - adding the flowlines sheet 
  if(add_sheet_for_streams == TRUE){
  # Build table for streams
  flowlines <- p3_flowlines_sf %>%
    st_drop_geometry() %>%
    as.data.frame() %>%
    filter(gnis_id != " ") %>%
    select(.data[[huc_column]], gnis_name, gnis_id) %>%
    distinct(.keep_all = T) %>%
    left_join(assc_lakes_df, by = huc_column) %>%
    relocate(assc_lakes) %>%
    arrange(assc_lakes, .data[[huc_column]], gnis_name, gnis_id) %>%
    rename(`Associated lakes` = assc_lakes, 
           `Stream name` = gnis_name,
           `GNIS ID` = gnis_id) %>%
    mutate(`Keep/discard` = "",
           Notes = "")
  
  create_workbook(df_to_export_as_wb = flowlines,
                  worksheet_name = "Streams",
                  manual_cols_to_add = NULL, 
                  out_file = out_file, create_wb = FALSE,
                  existing_wb_path = out_file, sheet_num = 2)
  }
  return(out_file)
}


create_huc_verification_table <- function(huc10_sf,
                                          huc10_name_col,
                                          huc8_sf,
                                          huc8_name_col,
                                          lake_column){

  
  ## Prep merge cols with just id and name
  huc10_nonsf <- huc10_sf %>% sf::st_drop_geometry() %>%
    select(all_of(c('HUC10', huc10_name_col))) %>% distinct() %>% 
    ## rename second col
    rename(HUC10_Name = 2)

  huc8_nonsf <- huc8_sf %>% sf::st_drop_geometry() %>%
    select(all_of(c('HUC8', huc8_name_col))) %>% distinct() %>%
    ## rename second col
    rename(HUC8_Name = 2)
  
  ## Tidy + left join 
  huc10_df <- huc10_sf %>%
    st_drop_geometry() %>% 
    select({{lake_column}}, HUC8,HUC10) %>%
    distinct() %>% 
    left_join(., huc10_nonsf, by = 'HUC10') %>% 
    left_join(., huc8_nonsf, by = 'HUC8') %>% 
    select({{lake_column}},HUC8, HUC8_Name, HUC10, HUC10_Name)
  
  ## return tidy dataset of HUC8 tied to our lakes and the HUC10s within these HUC8s - will use to verify HUC8/HUC10 scope
  return(huc10_df)
  
  }

## More generalized function for creating workbooks
create_workbook <- function(df_to_export_as_wb,
                            worksheet_name = 'Sheet 1',
                            manual_cols_to_add = NULL,
                            out_file,
                            create_wb = TRUE,
                            existing_wb_path = NULL, sheet_num = 1){
  
  ## adding extra com if 
  df_to_export_as_wb[manual_cols_to_add] <- NA
  
  # Create Excel workbook for export
  
  if(create_wb==TRUE){
    wb <- createWorkbook()
  }else{
    wb <- loadWorkbook(existing_wb_path)
    }
  
  # Add and format subbasin worksheet
  addWorksheet(wb, worksheet_name)
  writeDataTable(wb, sheet_num, df_to_export_as_wb, tableStyle = "TableStyleLight9")
  setColWidths(wb, sheet_num, cols = 1:4, widths = "auto")
  setColWidths(wb, sheet_num, cols = 5, widths = 20)
  
  # Export workbook
  saveWorkbook(wb, out_file, overwrite = T)
  
  return(out_file)
  
}
