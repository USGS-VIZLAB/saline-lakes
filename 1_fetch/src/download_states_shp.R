download_states_shp <- function(url, out_path = '1_fetch/in/states_shp'){
  
  #'@description download states shp directly from sbtools url 
  #'@param url s3 url path for direct download 
  #'@param out_path output folder path for spatial states shp. Default: '1_fetch/in/states_shp'
  
  tar_path <- '1_fetch/in/states.tar'
  httr::GET(url, write_disk(tar_path, overwrite = TRUE))
  untar(tar_path, exdir = out_path)
  
  return(out_path)

  }