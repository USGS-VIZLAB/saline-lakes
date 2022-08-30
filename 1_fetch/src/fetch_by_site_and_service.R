#' This function is derived and minorly adjusted from habs proxies fetch source function fetch_by_pcode_and_service_using_hucs.R
#' https://code.usgs.gov/wma/proxies/habs/wq-data-download/-/blob/main/1_fetch/src/fetch_by_pcode_and_service_using_hucs.R#L34

fetch_by_site_and_service <- function(sites_df, sites_col, lake_col, pcodes, service, start_date, end_date, incrementally = FALSE, split_num = 10) {
  
  lake_name <- sites_df %>% pull(.data[[lake_col]]) %>% head(1)
  message('Fetching nwis data from sites in ', lake_name, ' Watershed')
  
  if(!is.na(sites_df[lake_col])){
    start <- Sys.time()
    message('Nwis data fetch starting at ', start)
    
    ## pulling just sites no into a vector R 
    sites <- sites_df %>% pull(.data[[sites_col]])
    
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
    print(class(raw_data))
    
    if(is.data.frame(raw_data)){
      raw_data$lake_w_state <- lake_name
      raw_data <- raw_data %>% select(agency_cd, lake_w_state, site_no, everything())
    }
    
    if(is.null(raw_data)){
      raw_data <- data.frame(lake_w_state = lake_name,
                             site_no = NA)
    }
    
    end <- Sys.time()
    message('Nwis data fetch finished at ', end)
    
    # Outdated code from source that does not affect output here 
    # LP - Remove attributes, which typically have a timestamp associated
    # with them this can cause strange rebuilds of downstream data, 
    # even if the data itself is the same.
    attr(raw_data, "comment") <- NULL
    attr(raw_data, "queryTime") <- NULL
    attr(raw_data, "headerInfo") <- NULL
  
  } 
  
  # If no sites exists in the watershed site_no == NA. In that case, we return an empty dataframe
  else{
    
    message(paste(lake_name, ' has no NWIS sites'))
    
    raw_data <- data.frame(lake_w_state = lake_name,
                           site_no = NA)
  }
  
  return(raw_data)
}


fetch_nwis_fault_tolerantly <- function(sites, pcodes, service, start_date, end_date, max_tries = 10) {
  
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
    retry::retry(readNWISdata(sites = sites , 
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
