p3_export_csv(

# write dataframes to csv -------------------------------------------------------------------

tar_target(
  p3_nwis_dv_sw_data_csv,
  readr::write_csv(p1_nwis_dv_sw_data,
                   '1_fetch/out/p1_nwis_dv_sw_data.csv')
),

tar_target(
  p3_nwis_dv_gw_data_csv,
  readr::write_csv(p1_nwis_dv_gw_data,
                   '1_fetch/out/p1_nwis_dv_gw_data.csv')
),
# 
tar_target(
  p3_nwis_meas_sw_data_csv,
  readr::write_csv(p1_nwis_meas_sw_data,
                   '1_fetch/out/p1_nwis_meas_sw_data.csv')
),

tar_target(
  p3_nwis_meas_gw_data_csv,
  readr::write_csv(p1_nwis_meas_gw_data,
                   '1_fetch/out/p1_nwis_meas_gw_data.csv')
),

tar_target(
  p3_nwis_iv_gw_data_csv,
  {
    dir.create('1_fetch/out/iv_gw_data', showWarnings = F)
    for(i in names(p1_nwis_iv_gw_data_lst)){
      if(nrow(p1_nwis_iv_gw_data_lst[[i]]) > 1){
        filename <- paste0(snakecase::to_snake_case(p1_nwis_iv_gw_data_lst[[i]]$lake_w_state[1]) %>% 
                             substr(., 1, nchar(.) - 2), "iv_gw_data.csv")
        write.csv(p1_nwis_iv_gw_data_lst[[i]],
                  paste0('1_fetch/out/iv_gw_data/',filename)
        )
      }}}
), 

tar_target(
  p3_nwis_iv_sw_data_csv,
  {dir.create('1_fetch/out/iv_sw_data', showWarnings = F)
    for(i in names(p1_nwis_iv_sw_data_lst)){
      if(nrow(p1_nwis_iv_sw_data_lst[[i]]) > 1){
        filename <- paste0(snakecase::to_snake_case(p1_nwis_iv_sw_data_lst[[i]]$lake_w_state[1]) %>% 
                             substr(., 1, nchar(.) - 2), "iv_sw_data.csv")
        write.csv(p1_nwis_iv_sw_data_lst[[i]],
                  paste0('1_fetch/out/iv_sw_data/',filename)
        )
      }}})



)
