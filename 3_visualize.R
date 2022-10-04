source('3_visualize/src/prep_viz_data.R')
source('3_visualize/src/interactive_map.R')
source('3_visualize/src/generate_spreadsheet.R')


p3_targets_list <- list(

  ## Fetch and Process saline lakes via specifically built function that creates the final saline lakes shapefile 
  ## This fun not yet generalized, special handling of lakes included in fun
  ## NOTE - Change nhdhr_lakes_path param with either p1_download_nhdhr_lakes_path or p1_download_nhdhr_lakes_backup_path depending on where nhdhr lives
  tar_target(
    assc_lakes_df_huc8,
    assc_lakes_xwalk_df(huc_sf = p1_get_lakes_huc8_sf, huc_column = 'HUC8')
  ),
  
  tar_target(
    assc_lakes_df_huc10,
    assc_lakes_xwalk_df(huc_sf = p1_get_lakes_huc10_sf, huc_column = 'HUC10')
  ),
  
  tar_target(
    p3_saline_lakes_sf,
    prep_lakes_viz_sf(lakes_sf = p2_saline_lakes_sf, 
                      crs_plot = selected_crs)
  ),
  
  tar_target(
    p3_huc8_sf,
    prep_huc_viz_sf(huc_sf = p1_get_lakes_huc8_sf,
                     assc_lakes_df = assc_lakes_df_huc8,
                     crs_plot = selected_crs,
                    huc_column = 'HUC8')
  ),
   
  ## this takes a long time because rmapshaper::ms_simplify() is very slow for me when simplifying flowlines
  tar_target(
    p3_flowlines_sf,
    prep_flowlines_viz_sf(flowlines_sf = p2_lake_tributaries,
                          crs_plot = selected_crs) %>% 
      filter(streamorde >= 3)
  ),
  
  # tar_target(
  #   p3_gage_sites_sf,
  #   prep_gage_viz_sf(nwis_sites = p1_nwis_sites_from_nhdplus %>% st_as_sf(), 
  #                    huc8_sf = p3_huc8_sf, 
  #                    crs_plot = selected_crs)
  # ),
  
  # Output Spreadsheet #

  tar_target(
    p3_feedback_spreadsheet_xlsx,
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
  p3_lake_HUC10_spreadsheet_xlsx,
  create_worksheet(df_to_export_as_wb = p2_huc_boundary_xwalk_df,
                  worksheet_name = 'Lake_huc6_huc8_huc10',
                  manual_cols_to_add = 'Part of Watershed (Yes/No)',
                  out_file = '3_visualize/out/lake_huc6_huc8_huc10_structure_table.xlsx'),
  format = 'file'
   ),

  ## This is outdated and will not run
  # tar_target(
  #   p3_interactive_map_leaflet,
  #   build_map_leaflet(p3_huc8_sf = p2_lake_watersheds_dissolved,
  #                     p3_saline_lakes_sf = p3_saline_lakes_sf,
  #                     p3_flowlines_sf = p3_flowlines_sf,
  #                     p3_gage_sites_sf = p3_gage_sites_sf)
  # 
  # ),
  
  # Render Markdown #
  
  ## note this leaflet is adapted from previous leaflet output map and therefore still has the outdated gage sites outside boundary.
  tar_target(
    p3_markdown,
    {output_file <- '3_visualize/out/watershed_extent_update_0928.html'
    rmarkdown::render(input = 'watershed_extent_update_0928.Rmd',
                                output_format = 'html_document',
                                output_file = output_file)
    return(output_file)
    }, 
    format = 'file')
  
)
