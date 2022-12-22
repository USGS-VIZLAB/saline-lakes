source('4_outputs/src/write_functions.R')

p4_output_targets_list <- list(

# output cont dv dfs -------------------------------------------------------------------

## writing daily sw values to a single rds 
tar_target(
  p4_nwis_dv_sw_data_rds,
  write_rds(p2_nwis_dv_sw_data,
            "4_outputs/out/p4_nwis_dv_sw_data.rds"),
  format = "file"
  ),

## writing daily gw values to a single rds
tar_target(
  p4_nwis_dv_gw_data_rds, 
  write_rds(p2_nwis_dv_gw_data,
            "4_outputs/out/p4_nwis_dv_gw_data.rds"),
  format = "file"
  ),

# output disc. field meas dfs -------------------------------------------------------------------

## writing field measurement sw values to a single rds 
tar_target(
  p4_nwis_meas_sw_data_rds,
  write_rds(p2_nwis_meas_sw_data,
            '4_outputs/out/p4_nwis_meas_sw_data.rds')
),

## writing field measurement gw values to a single rds
tar_target(
  p4_nwis_meas_gw_data_rds,
  write_rds(p2_nwis_meas_gw_data,
            '4_outputs/out/p4_nwis_meas_gw_data.rds')
),

# output cont. iv list of dfs -------------------------------------------------------------------

# COMMENTED OUT BECAUSE THIS TAKES A LONG TIME TO WRITE #

## writing iv data to lake specific csvs
# tar_target(
#   p4_nwis_iv_gw_data_csv,
#   write_iv_csvs(iv_df_lst = p1_nwis_iv_sw_data_lst,
#                 output_folder_path = '4_outputs/out',
#                 data_folder_name = 'iv_gw_data'),
#   format = 'file'),

# tar_target(
#   p4_nwis_iv_sw_data_csv,
#   write_iv_csvs(iv_df_lst = p1_nwis_iv_sw_data_lst,
#                 output_folder_path = '4_outputs/out',
#                 data_folder_name = 'iv_sw_data'),
#   format = 'file')


# output shapefiles -------------------------------------------------------

# exporting saline lakes shp 
tar_target(p4_saline_lakes_shp,
           write_shp(p2_saline_lakes_sf,
                    'out_shp/saline_lakes.shp'),
           format = 'file'
           ),

# exporting saline lakes shp 
tar_target(p4_lake_watersheds_shp,
           write_shp(p2_lake_watersheds_dissolved,
                     'out_shp/p2_lake_watersheds.shp'),
           format = 'file'
)

## exporting flines shp 
# COMMENTED OUT BECAUSE THIS TAKES A LONG TIME TO WRITE #
# tar_target(p4_lake_tributaries_shp,
#            write_shp(p2_lake_tributaries,
#                     'out_shp/p2_lake_tributaries.shp'),
#            format = 'file'
#            ),



# Output reports -----------------------------------------------------------------

# COMMENTED OUT BECAUSE Outdated and difficult to render in targets pipeline #
## Render Markdown #
## built in a {} fun chunk to be able to export file path and save a 'file' target
## Note: the input Rmd for the rmarkdown::render() function requires that the input sits in root folder of WD, otherwise is resets the wd for you.
## Get crytic message - mine was that the `4_reports/out/` isn't a directory.
# tar_target(
#   p4_markdown,
#   {output_file <- '4_reports/out/watershed_extent_update_0928.html'
#   rmarkdown::render(input = 'watershed_extent_update_0928.Rmd',
#                     output_format = 'html_document',
#                     output_file = output_file,
#                     quiet = TRUE)
#   return(output_file)
#   },
#   format = 'file')


)
