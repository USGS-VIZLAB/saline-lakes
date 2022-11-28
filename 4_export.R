source('4_reports/src/write_functions.R')

p4_export_csv_targets_list <- list(

# exports dfs -------------------------------------------------------------------

## writing daily sw values to a single csv 
tar_target(
  p4_nwis_dv_sw_data_rds,
  write_rds(p2_nwis_dv_sw_data,
            "4_reports/out/p1_nwis_dv_sw_data.rds"),
  format = "file"
  ),

## writing daily gw values to a single csv
tar_target(
  p4_nwis_dv_gw_data_rds, 
  write_rds(p2_nwis_dv_gw_data,
            "4_reports/out/p1_nwis_dv_gw_data.rds"),
  format = "file"
  ),

## writing field measurement sw values to a single csv 
tar_target(
  p4_nwis_meas_sw_data_rds,
  readr::write_csv(p1_nwis_meas_sw_data,
                   '4_reports/out/p1_nwis_meas_sw_data.csv')
),

## writing field measurement gw values to a single csv 
tar_target(
  p4_nwis_meas_gw_data_rds,
  readr::write_csv(p1_nwis_meas_gw_data,
                   '4_reports/out/p1_nwis_meas_gw_data.csv')
),

## writing iv data to lake specific csvs
# tar_target(
#   p4_nwis_iv_gw_data_csv,
#   write_iv_csvs(iv_df_lst = p1_nwis_iv_sw_data_lst,
#                 output_folder_path = '4_reports/out',
#                 data_folder_name = 'iv_gw_data'),
#   format = 'file'),

# tar_target(
#   p4_nwis_iv_sw_data_csv,
#   write_iv_csvs(iv_df_lst = p1_nwis_iv_sw_data_lst,
#                 output_folder_path = '4_reports/out',
#                 data_folder_name = 'iv_sw_data'),
#   format = 'file')



# export shapefiles -------------------------------------------------------

tar_target(p4_saline_lakes_shp,
           write_shp(p2_saline_lakes_sf,
                    'out_shp/saline_lakes.shp'),
           format = 'file'
           ),
## Commenting out because taking too long 
# tar_target(p4_lake_tributaries_shp,
#            write_shp(p2_lake_tributaries,
#                     'out_shp/p2_lake_tributaries.shp'),
#            format = 'file'
#            ),

tar_target(p4_lake_watersheds_shp,
           write_shp(p2_lake_watersheds_dissolved,
                    'out_shp/p2_lake_watersheds.shp'),
           format = 'file'
           )

)
