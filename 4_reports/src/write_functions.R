#' @description write_iv_csvs writes separate csvs for each item in a list of df. Used for writing the individual iv datasets stored in p1_nwis_iv_gw_data_lst and p1_nwis_iv_sw_data_lst
#' @param iv_df_lst list obj of dataframes  
#' @param output_folder_path folder where the output folder of data will be stored
#' @param data_folder_name new folder name to be created in the output_folder_path and in which we will store the output csv
#' @example write_iv_csvs(iv_df_lst = p1_nwis_iv_gw_data_lst, output_folder_path = '4_reports/out', data_folder_name = 'iv_gw_data')

write_iv_csvs <- function(iv_df_lst, output_folder_path, data_folder_name){
  
  dir <- file.path(output_folder_path, data_folder_name)
  dir.create(dir, showWarnings = F)
  
  for(i in names(iv_df_lst)){
      if(nrow(iv_df_lst[[i]]) > 1){
        filename <- paste0(snakecase::to_snake_case(iv_df_lst[[i]]$lake_w_state[1]) %>% 
                             substr(., 1, nchar(.) - 2),
                           data_folder_name, ".csv")
        write.csv(iv_df_lst[[i]],
                  file.path(dir,filename)
        )
      }
  }
  return(dir)
}


#' @description write_shp 
#' @param data 
#' @param out_file

write_shp <- function(data, out_file, quiet = TRUE){
  
  sf::st_write(obj = data, out_file, quiet = quiet, append = FALSE)
  
  print(paste0('saving to ',out_file))
  
  return(out_file)
  
}

#' @description write_rds
#' @param data 
#' @param out_file

write_rds <- function(data, out_file){
  saveRDS(data, out_file)
  print(paste0('saving to ',out_file))
  return(out_file)
  }
  

