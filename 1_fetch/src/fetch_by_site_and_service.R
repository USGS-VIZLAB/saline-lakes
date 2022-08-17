#' This function is derived and minorly adjusted from habs proxies fetch source function fetch_by_pcode_and_service_using_hucs.R
#' https://code.usgs.gov/wma/proxies/habs/wq-data-download/-/blob/main/1_fetch/src/fetch_by_pcode_and_service_using_hucs.R#L34

fetch_by_site_and_service <- function(sites, pcodes, service, start_date, end_date, incrementally = FALSE, split_num = 10) {
  
  ## incrementally added as binomial param to chunk the sites in order to send requests incrementally through an lapply 
  if(incrementally == TRUE){
    sites_list <- sites %>% split(., ceiling(seq_along(.)/split_num))
    start <- Sys.time()
    message('nwis data fetch starting at', start)
    raw_data <- lapply(sites_list, function(sites_subset){fetch_nwis_fault_tolerantly(sites_subset,
                                                                                     pcodes,
                                                                                     service,
                                                                                     start_date,
                                                                                     end_date)}) %>% bind_rows()
    end <- Sys.time()
    message('nwis data fetch finished at', end)
  }else{
    raw_data <- fetch_nwis_fault_tolerantly(sites, pcodes, service, start_date, end_date)
  }
  # Remove attributes, which typically have a timestamp associated
  #  with them this can cause strange rebuilds of downstream data, 
  #   even if the data itself is the same.
  attr(raw_data, "comment") <- NULL
  attr(raw_data, "queryTime") <- NULL
  attr(raw_data, "headerInfo") <- NULL
  
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