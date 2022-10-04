source('3_visualize/src/generate_spreadsheet.R')

p1_feeback_xlsx_targets_list <- list(
  
# Output Spreadsheet #
tar_target(
  p1_feedback_spreadsheet_xlsx,
  build_feedback_spreadsheet(p1_get_lakes_huc_sf = p1_get_lakes_huc8_sf,
                             huc_column = 'HUC8',
                             p3_flowlines_sf = p2_lake_tributaries,
                             assc_lakes_df = assc_lakes_df_huc8,
                             ## not adding streams for now because we have switched out p3_flowlines_sf with specified tributaries, and does not have HUC8 col right now
                             add_sheet_for_streams = FALSE,
                             out_file = "3_visualize/out/Subbasin_KeepDiscard_huc8.xlsx"),
  format = "file"
),

## output huc6_huc8_huc10 structure spreadsheet from the xwalk table build in 2_process.R 
## This is spreadsheet is designed to manually edited so that users can say whether a huc10 (a higher oder huc 8 and/or huc6 is in or out of watershed) 
tar_target(
  p1_lake_HUC10_spreadsheet_xlsx,
  create_worksheet(df_to_export_as_wb = p2_huc_boundary_xwalk_df,
                   worksheet_name = 'Lake_huc6_huc8_huc10',
                   manual_cols_to_add = 'Part of Watershed (Yes/No)',
                   out_file = '3_visualize/out/lake_huc6_huc8_huc10_structure_table.xlsx'),
  format = 'file'
)

)