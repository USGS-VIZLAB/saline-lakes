# export simple plots of data stored in list 

line_plot_iv <- function(data,
                         selected_measurement_col = 'X_00060_00000',date_col = 'dateTime',
                         output_suffix = 'iv_sw_dis_data',
                         img_file_type = 'png', output_folder_path = '3_visualize/out'){
      
      ## Creating folder for vis and defining path
      output_vis_path <- file.path(output_folder_path,output_suffix)
      dir.create(output_vis_path, showWarnings = FALSE)
      
      lake <- data$lake_w_state[1]
      print(lake)
      
      ## Plot
      if(nrow(data)>1){
        data %>% 
        ggplot2::ggplot(.,
                        aes(x= .data[[date_col]],
                            y = .data[[selected_measurement_col]]), color = 'firebrick')+
        geom_line()+
        theme_bw()
      ## saving to appropriate location + editing name
      ggsave(filename = paste0(snakecase::to_snake_case(lake),
                                                        '_',
                                                        output_suffix,
                                                        '.',
                                                        img_file_type),
             device = 'png',
             path = output_vis_path)
      } else{print(paste(data$lake_w_state[1],'has no iv data'))}
      

}



line_plot_dv <- function(data,
                         selected_measurement_col = 'X_00060_00003',
                         date_col = 'dateTime',
                         output_suffix = 'dv_sw_dis_data',
                         img_file_type = 'png', output_folder_path = '3_visualize/out'){

  ## Creating folder for vis and defining path
  output_vis_path <- file.path(output_folder_path,output_suffix)
  dir.create(output_vis_path, showWarnings = FALSE)
  ## Plot
  for(lake in unique(data$lake_w_state)){
    print(lake)
    filtered_data <- data %>% filter(lake_w_state == lake) 
    if(nrow(filtered_data) > 1){
      ggplot2::ggplot(filtered_data, aes(x= .data[[date_col]], y = .data[[selected_measurement_col]]),
                      color = 'firebrick')+
        geom_line()+
        theme_bw()
      
      ggsave(filename = paste0(snakecase::to_snake_case(lake),
                               '_',
                               output_suffix,
                               '.',
                               img_file_type),
             device = 'png',
             path = output_vis_path)
      
    }else{print(paste(lake,'has no dv data'))}
    ## saving to appropriate location + editing name
  }
}

# line_plot_dv(data = p1_nwis_dv_gw_data,
#              selected_measurement_col = 'X_72019_00002',
#              date_col = 'dateTime',
#              output_suffix = 'dv_gw_depth_data',
#              img_file_type = 'png',
#              output_folder_path = '3_visualize/out')
