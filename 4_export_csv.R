source('4_reports/src/write_iv_csv.R')

p4_export_csv_targets_list <- list(

# write dataframes to csv -------------------------------------------------------------------

## writing daily sw values to a single csv 
tar_target(
  p4_nwis_dv_sw_data_csv,
  readr::write_csv(p1_nwis_dv_sw_data,
                   '4_reports/out/p1_nwis_dv_sw_data.csv')
),

## writing daily gw values to a single csv
tar_target(
  p4_nwis_dv_gw_data_csv,
  readr::write_csv(p1_nwis_dv_gw_data,
                   '4_reports/out/p1_nwis_dv_gw_data.csv')
),

## writing field measurement sw values to a single csv 
tar_target(
  p4_nwis_meas_sw_data_csv,
  readr::write_csv(p1_nwis_meas_sw_data,
                   '4_reports/out/p1_nwis_meas_sw_data.csv')
),

## writing field measurement gw values to a single csv 
tar_target(
  p4_nwis_meas_gw_data_csv,
  readr::write_csv(p1_nwis_meas_gw_data,
                   '4_reports/out/p1_nwis_meas_gw_data.csv')
),

## writing iv data to lake specific csvs
tar_target(
  p4_nwis_iv_gw_data_csv,
  write_iv_csvs(iv_df_lst = p1_nwis_iv_sw_data_lst,
                output_folder_path = '4_reports/out',
                data_folder_name = 'iv_gw_data'),
  format = 'file'),

tar_target(
  p4_nwis_iv_sw_data_csv,
  write_iv_csvs(iv_df_lst = p1_nwis_iv_sw_data_lst,
                output_folder_path = '4_reports/out',
                data_folder_name = 'iv_sw_data'),
  format = 'file')

)
