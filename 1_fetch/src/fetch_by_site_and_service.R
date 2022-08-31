#' This function is derived and minorly adjusted from habs proxies fetch source function fetch_by_pcode_and_service_using_hucs.R
#' https://code.usgs.gov/wma/proxies/habs/wq-data-download/-/blob/main/1_fetch/src/fetch_by_pcode_and_service_using_hucs.R#L34

fetch_by_site_and_service <- function(sites_df, sites_col, lake_col, pcodes, service, start_date, end_date, incrementally = FALSE, split_num = 10) {
  #' @description Pull nwis data for selected sites. This function expected a sites-df input for it to be applied as on branched target
  #' @param sites_df dataframe that contains list of sites. THis data frame should outline all sites belonging to each lake
  #' @param sites_col col name as string of the sites_df that contains list of sites
  #' @param lake_col col name as string from teh sites_sf that contains lakes.  
  #' @param pcodes nwis parameter codes. str or vector of str
  #' @param service NWIS data service. See NWIS readNWISdata() fun for details (e.g. 'measurements', 'gwlevels', 'dv', 'iv')
  #' @param start_date str. start date of data query
  #' @param end_date str. end date of data query
  #' @param incrementally logical. If using fun for a large data pull across large list of sites, worth running this incrementally
  #' @param split_num default = 10. If incrementally = TRUE, the list of sites will be split into groups to incrementally fetch nwis data
  
  ## Pulling lake names. Useful as this fun is used in target branching and this allow to populate the branch output
  ## Note - this likely will be confusing if the function is used outside of branched format
  lake_name <- sites_df %>% pull(.data[[lake_col]]) %>% head(1)
  message('Fetching nwis data from sites in ', lake_name, ' watershed')
  
  if(!all(is.na(sites_df[sites_col]))){
    start <- Sys.time()
    message('Nwis data fetch starting at ', start)
    
    ## Pulling just sites no into a vector R 
    sites <- sites_df %>% filter(!is.na(site_no)) %>% pull(.data[[sites_col]])

    ## Incrementally added as binomial param to chunk the sites in order to send requests incrementally through the lapply 
    ## set iv requests as incrementally == T since it is many more data points, while dv requests incrementally == F
    if(incrementally == TRUE){
  
      sites_list <- sites %>% split(., ceiling(seq_along(.)/split_num))
      
      raw_data <- lapply(sites_list, function(sites_subset){
        fetch_nwis_fault_tolerantly(sites_subset,
                                    pcodes,
                                    service,
                                    start_date,
                                    end_date)}) %>% bind_rows()
      
    } else{
      
      raw_data <- fetch_nwis_fault_tolerantly(sites,
                                              pcodes,
                                              service,
                                              start_date,
                                              end_date)
      
    }
    
    # Prepping final dataframe to be returned - should be easy to bind even if lake has no data 
    ## printing type to see if select can be applied to raw_data. If empty cannot be applied
    # Checking output of raw_data
    print(class(raw_data))
    
    ## Creating empty df if output is null. Getting various invalid outputs so aiming catching them all in this if statement 
    if((is.null(raw_data)) | (any(nrow(raw_data) == 0)) | ("No.sites.data.found.using.the.selection.criteria.specified." %in% colnames(raw_data))){
      
      final_data <- data.frame(lake_w_state = lake_name, site_no = NA)
    }
    
    ## for dataframes larger than nrow() == 0 
    else if(is.data.frame(raw_data)){
      final_data <- raw_data %>% mutate(lake_w_state = lake_name) %>% 
        select(agency_cd, lake_w_state, site_no, everything())
    }
    
        
    end <- Sys.time()
    message('Nwis data fetch finished at ', end)
    
    # Outdated code from source that does not affect output here 
    # LP - Remove attributes, which typically have a timestamp associated
    # with them this can cause strange rebuilds of downstream data, 
    # even if the data itself is the same.
    attr(final_data, "comment") <- NULL
    attr(final_data, "queryTime") <- NULL
    attr(final_data, "headerInfo") <- NULL
  
  } 
  
  # If no sites exists in the watershed site_no == NA. In that case, we return an empty dataframe
  else{
    
    message(paste(lake_name, ' has no NWIS sites'))
    
    final_data <- data.frame(lake_w_state = lake_name,
                           site_no = NA)
  }
  
  return(final_data)
}


fetch_nwis_fault_tolerantly <- function(sites, pcodes, service, start_date, end_date, max_tries = 10) {
  #' @param sites str or vector of str. single site or vector of sites to query nwis data from
  #' @param pcodes str or vector of str. parameter codes to get data from (e.g. c('00060','00065'))
  #' @param service NWIS data service. See NWIS readNWISdata() fun for details (e.g. 'measurements', 'gwlevels', 'dv', 'iv')
  #' @param start_date str. start date of data query
  #' @param end_date str. end date of data query
  #' @param max_tries default 10. Number of tries for fetching NWIS data before returning NULL
  
  ## adding condition for surface water because service = 'measurements' does not work with readNWISdata
  if(service == 'measurements'){
    data_returned <- tryCatchLog(
      retry::retry(readNWISmeas(siteNumbers = sites,
                         startDate = start_date,
                         endDate = end_date),
            until = function(val, cnd) "data.frame" %in% class(val),
            max_tries = max_tries),
      error = function(e) return()
    )
  }else{
  data_returned <- tryCatchLog(
    retry::retry(readNWISdata(sites = sites, 
                       parameterCd = pcodes,
                       startDate = start_date,
                       endDate = end_date,
                       service = service),
          until = function(val, cnd) "data.frame" %in% class(val),
          max_tries = max_tries),
    error = function(e) return()
  )
  }
  # Noticed that some UV calls return a data.frame with a tz_cd column
  # and nothing else. These should be considered empty.
  # For example: 
  # readNWISdata(huc = "07120001", parameterCd = "00021", startDate = "2021-07-01",
  #              endDate = "2021-07-03", service = "uv")
  if(nrow(data_returned) == 0 & "tz_cd" %in% names(data_returned)) {
    return()
  } else {
    return(data_returned)
  }
} 
