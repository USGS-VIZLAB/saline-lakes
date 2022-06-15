download_nhdhr_lakes <- function(lakes_df, point_geom_col = 'Point_geometry', output_file_path){
  #' @description Download the nhdhr data for huc08 basins given a list of lakes and point coordinates 
  #' @param lakes_df lakes_dataset with point coords of selected lakes
  #' @param point_geom_col char. Name of point geom column in lakes_df
  #' @param output_file_path out filepath for download data. Download process will create subfolders  for huc areas
  #' @value return list of file paths of the downloaded data  
  
  ## Define temp dir in Data folder
  nhdhr_dir <- output_file_path

  ## Get huc08 for focal lakes and extract comids
  huc8 <- get_huc8(AOI = lakes_df[point_geom_col])
  
  huc04 <- substr(huc8$huc8, start = 1, stop = 4) %>% unique()

  ## download 
  start <- Sys.time()
  nhdplusTools::download_nhdplushr(nhdhr_dir, huc04)
  end <- Sys.time()
  
  print(end - start)
  
  return(list.files(nhdhr_dir))
  
}



