source('3_visualize/src/line_plts.R')

p3_viz_targets_list <- list(
  
  # tar_target(p3_nwis_iv_sw_dis_png,
  #            for(i in p1_nwis_iv_sw_data_lst){
  #            line_plot_iv(data = i,
  #                         selected_measurement_col = 'X_00060_00000',
  #                         date_col = 'dateTime',
  #                         output_suffix = 'iv_sw_dis_data',
  #                         img_file_type = 'png',
  #                         output_folder_path = '3_visualize/out')
  #            }
  #            # return(paste0('3_visualize/out','iv_sw_dis_data'))
  # ),
  # 
  # tar_target(p3_nwis_iv_sw_gageheight_png,
  #            for(i in p1_nwis_iv_sw_data_lst){
  #              line_plot_iv(data = i,
  #                           selected_measurement_col = 'X_00065_00000',
  #                           date_col = 'dateTime',
  #                           output_suffix = 'iv_sw_gageheight_data',
  #                           img_file_type = 'png',
  #                           output_folder_path = '3_visualize/out')
  #            }
  #           # return(paste0('3_visualize/out','iv_sw_gageheight_data')
  # ),
  # 
  # tar_target(p3_nwis_iv_gw_depth_png,
  #            for(i in p1_nwis_iv_gw_data_lst){
  #              line_plot_iv(data = i,
  #                           selected_measurement_col = 'X_72019_00003',
  #                           date_col = 'dateTime',
  #                           output_suffix = 'iv_gw_dpth_data',
  #                           img_file_type = 'png',
  #                           output_folder_path = '3_visualize/out')
  #            }
  #            # return(paste0('3_visualize/out','iv_sw_dis_data'))
  # ),
  
  tar_target(
    p3_nwis_dv_sw_dis_png,
    line_plot_dv(data = p1_nwis_dv_sw_data,
                 selected_measurement_col = 'X_00060_00003',
                 date_col = 'dateTime',
                 output_suffix = 'dv_sw_dis_data',
                 img_file_type = 'png',
                 output_folder_path = '3_visualize/out')
             ),
  
  tar_target(
    p3_nwis_dv_sw_gageheight_png,
    line_plot_dv(data = p1_nwis_dv_sw_data,
                 selected_measurement_col = 'X_00065_00003',
                 date_col = 'dateTime',
                 output_suffix = 'dv_sw_gage_data',
                 img_file_type = 'png',
                 output_folder_path = '3_visualize/out')
  ),
  
  tar_target(
    p3_nwis_dv_gw_depth_png,
    line_plot_dv(data = p1_nwis_dv_gw_data,
                 selected_measurement_col = 'X_72019_00003',
                 date_col = 'dateTime',
                 output_suffix = 'dv_gw_depth_data',
                 img_file_type = 'png',
                 output_folder_path = '3_visualize/out')
  )
  
)
 