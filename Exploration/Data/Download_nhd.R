library(sf)
library(nhdplusTools)
library(dplyr)
library(stringr)

download_nhdhr <- function(lakes_df, point_geom_col = 'Point_geometry', output_file_path){
  #' @description 
  #' @param lakes_df lakes_dataset with point coords of selected lakes
  #' @param point_geom_col char. Name of point geom column in lakes_df
  #' @param output_file_path out filepath for download data. Download process will create subfolders  for huc areas
  
  ## Define temp dir in Data folder
  nhdhr_dir <- file_path

  ## Get huc08 for focal lakes and extract comids
  huc8 <- get_huc8(AOI = lakes_df[point_geom_col])
  
  huc8_comids <- substr(huc8$huc8, start = 1, stop = 4) %>% unique()

  ## nhdplustools
  nhdplusTools::download_nhdplushr(nhdhr_dir, huc8_comids)
  
  return(list.files(nhdhr_dir))
  
}

