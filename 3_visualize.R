source('3_visualize/src/line_plts.R')

p3_viz_targets_list <- list(
  
  tar_target(p3_nwis_iv_sw_dis_png,
             for(i in p1_nwis_iv_sw_data_lst){
             line_plot_iv(data = i,
                          selected_measurement_col = 'X_00060_00000',
                          date_col = 'dateTime',
                          output_suffix = 'iv_sw_dis_data',
                          img_file_type = 'png',
                          output_folder_path = '3_visualize/out')
             }
             # return(paste0('3_visualize/out','iv_sw_dis_data'))
  ),
  
  tar_target(p3_nwis_iv_sw_gageheight_png,
             for(i in p1_nwis_iv_sw_data_lst){
               line_plot_iv(data = i,
                            selected_measurement_col = 'X_00065_00000',
                            date_col = 'dateTime',
                            output_suffix = 'iv_sw_gageheight_data',
                            img_file_type = 'png',
                            output_folder_path = '3_visualize/out')
             }
            # return(paste0('3_visualize/out','iv_sw_gageheight_data')
  ),
  
  tar_target(
    p3_nwis_dv_sw_dis_png,
    line_plot_dv(data = p1_nwis_dv_sw_data,
                 selected_measurement_col = 'X_00060_00003',
                 date_col = 'dateTime',
                 output_suffix = 'dv_dw_dis_data',
                 img_file_type = 'png',
                 output_folder_path = '3_visualize/out')
             ),
  
  tar_target(
    p3_nwis_dv_sw_gageheight_png,
    line_plot_dv(data = p1_nwis_dv_sw_data,
                 selected_measurement_col = 'X_00065_00003',
                 date_col = 'dateTime',
                 output_suffix = 'dv_dw_gage_data',
                 img_file_type = 'png',
                 output_folder_path = '3_visualize/out')
  ),
  
  tar_target(
    p3_nwis_dv_gw_gageheight_png,
    line_plot_dv(data = p1_nwis_dv_gw_data,
                 selected_measurement_col = 'X_72019_00002',
                 date_col = 'dateTime',
                 output_suffix = 'dv_gw_depth_data',
                 img_file_type = 'png',
                 output_folder_path = '3_visualize/out')
  )
  
)
             
            
  
  
  
  
# )
# 
# 
# 
# targets::tar_load(p1_nwis_iv_gw_data_lst)
# targets::tar_load(p1_nwis_iv_sw_data_lst)
# 
# counter = 0
# for(i in names(p1_nwis_iv_gw_data_lst)){
#   counter = counter + 1
#   if(nrow(p1_nwis_iv_gw_data_lst[[i]]) > 1){
#     print(paste(counter, p1_nwis_iv_gw_data_lst[[i]]$lake_w_state[1]))
#     p1_nwis_iv_gw_data_lst[[i]] %>% 
#       ggplot2::ggplot(.,aes(x=dateTime, y = X_72019_00000, color = lake_w_state))+
#       geom_point()+
#       theme_bw()
#   
#     ggsave(filename = snakecase::to_snake_case(paste0(p1_nwis_iv_gw_data_lst[[i]]$lake_w_state[1],"_iv_gw_data")),
#         device = 'png',
#         path = '3_visualize/out')
#   }
# }
#     
# counter = 0
# for(i in names(p1_nwis_iv_sw_data_lst)){
#   counter = counter + 1
#   print(counter)
#   if(nrow(p1_nwis_iv_sw_data_lst[[i]]) > 1){
#     print(paste(counter, p1_nwis_iv_sw_data_lst[[i]]$lake_w_state[1]))
#     p1_nwis_iv_sw_data_lst[[i]] %>% 
#       ggplot2::ggplot(.,aes(x=dateTime, y = X_00060_00000, color = lake_w_state))+
#       geom_line()+
#       theme_bw()
#     
#     ggsave(filename = snakecase::to_snake_case(paste0(p1_nwis_iv_sw_data_lst[[i]]$lake_w_state[1],"_iv_sw_dis_data.png")),
#            device = 'png',
#            path = '3_visualize/out')
#   }
# }
#   
# p1_nwis_iv_sw_data_lst[[1]] %>% head(1000) %>%  
#   ggplot2::ggplot(.,aes(x=dateTime, y = X_00060_00000, color = lake_w_state))+
#   geom_point()+
#   theme_bw()
# 
#   
