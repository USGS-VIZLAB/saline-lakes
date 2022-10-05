source('1_build_raw_feedback_xlsx/src/generate_spreadsheet.R')

p1_feeback_xlsx_targets_list <- list(
  
  # Lake Huc structure table #
  
  ## Creating simplified df that structures the huc10 within the HUC 8 of our selected lakes -exporting the xlsx for manual review in view of feedback
  tar_target(
    p2_huc_boundary_xwalk_df, 
    create_huc_verification_table(huc10_sf = p1_get_lakes_huc10_sf,
                                  huc10_name_col = 'Name',
                                  huc8_sf = p1_get_lakes_huc8_sf,
                                  huc8_name_col = 'Name',
                                  huc6_sf = p1_get_lakes_huc6_sf,
                                  huc6_name_col = 'Name',
                                  lake_column = 'lake_w_state')
  ),
  
  # Raw Output Spreadsheet #
  ## This target outputs huc6_huc8_huc10 structure spreadsheet from the xwalk table build in 2_process.R 
  ## This is spreadsheet is designed to manually edited so that project members can manually choose what hus are in and out of scope
  ## The edited version of this spreadsheet is already in the repo - under 1_fetch/in
  
  tar_target(
    p1_lake_HUC10_spreadsheet_xlsx_outpath, '1_build_raw_feedback_xlsx/out/lake_huc6_huc8_huc10_structure_table.xlsx'),
  
  tar_target(
    p1_lake_HUC10_spreadsheet_xlsx,
    create_worksheet(df_to_export_as_wb = p2_huc_boundary_xwalk_df,
                     worksheet_name = 'Lake_huc6_huc8_huc10',
                     manual_cols_to_add = 'Part of Watershed (Yes/No)',
                     out_file = p1_lake_HUC10_spreadsheet_xlsx_outpath),
    format = 'file'
  )
)