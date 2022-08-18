#' The functions below fetch downloaded nhd data from nhdplushr and non-hr
#' nhdplusTools is a required library 

download_nhdhr_data <- function(nhdhr_gdb_path, huc04_list){
  #' @param nhdhr_gdb_path nhdhr character directory to save output gdb into
  #' @param huc04_list character vector of hydrologic region(s) 04 to download.e.g. p1_huc04_for_download
  
  nhdplushr_subdir <- download_nhdplushr(nhdhr_gdb_path, huc04_list)
  print(nhdplushr_subdir)
  
  # return path one level higher so it can be a stand alone file target 
  return(nhdhr_gdb_path)

}

get_downloaded_nhd_data <- function(gdb_path, out_gpkg_path, layer){
  #' @description wrapper function for get_nhdplushr
  #' @param gbd_path downloaded gdb from nhdplushr (this should be the output of nhdplusTools::download_nhdplushr())
  #' @param out_gpkg_path outpath for the gpkg in which the different layers of nhdplushr data will be stored
  #' @param layer layer or vector of layers. see details for layer param in nhdplusTools::get_nhdplushr()
    
  get_nhdplushr(hr_dir = gdb_path,
                out_gpkg = out_gpkg_path,
                layer= layer)
  
  return(out_gpkg_path)
  
}




