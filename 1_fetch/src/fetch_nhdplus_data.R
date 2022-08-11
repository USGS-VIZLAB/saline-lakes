#' The functions below fetch downloaded nhd data from nhdplushr and non-hr
#' nhdplusTools is a required library 

get_downloaded_nhd_data <- function(gdb_path, out_gpkg_path, layer){
  #' @description wrapper function for get_nhdplushr
  #' @param gbd_path downloaded gdb from nhdplushr (this should be the output of nhdplusTools::download_nhdplushr())
  #' @param out_gpkg_path outpath for the gpkg in which the differen layers of nhdplushr data will be stored
  #' @param layer layer or vector of layers. see details for layer param in nhdplusTools::get_nhdplushr()
    
  get_nhdplushr(hr_dir = gdb_path,
                out_gpkg = out_gpkg_path,
                layer= layer)
  
  return(out_gpkg_path)
  
}




