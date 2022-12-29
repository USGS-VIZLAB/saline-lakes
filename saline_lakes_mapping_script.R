library(ggplot2)
library(tidyverse)
library(sf)
library(mapview)

# read in data  -----------------------------------------------------------

targets::tar_load(p4_nwis_dv_gw_data_rds)
targets::tar_load(p4_nwis_dv_sw_data_rds)
targets::tar_load(p3_saline_lakes_sf)
targets::tar_load(p2_site_in_watersheds_sf)
targets::tar_load(p2_lake_watersheds_dissolved)
targets::tar_load(p2_saline_lakes_sf)
targets::tar_load(p2_lake_tributaries)
targets::tar_load(p1_nwis_meas_sw_data)
targets::tar_load(p1_nwis_meas_gw_data)


nwis_dv_gw_data <- readRDS("p1_nwis_dv_gw_data.rds")
nwis_dv_sw_data <- readRDS("p1_nwis_dv_sw_data_rds")

wq_data <- readRDS('harmonized_wqp_data_added_cols.rds')
wq_sites <- readRDS('harmonized_wqp_sites.rds') 

wq_data$MonitoringLocationIdentifier %>% unique() %>% length()
wq_sites$MonitoringLocationIdentifier %>% unique() %>% length()


# check dims --------------------------------------------------------------

nwis_dv_gw_data %>% dim()
nwis_dv_sw_data %>% dim()

nwis_dv_sw_data$dateTime %>% max()
nwis_dv_gw_data$dateTime %>% max()

# general items: ----------------------------------------------------------

us_sf <- st_as_sf(maps::map('state', plot=F, fill=T)) %>% st_transform(4326)

labels_df <- p3_saline_lakes_sf %>%
  mutate(label = gsub('Lake: ','',label)) %>%
  select(label, X, Y) %>% st_drop_geometry()

map_bbox <- st_bbox(p2_lake_watersheds_dissolved)

# map fun -----------------------------------------------------------------

## general map that includes, lakes, labels
general_map <- function(watershed_sf, lake_sf, labels_df, basemap, map_bbox, title = 'Saline Lakes and Watersheds'){   
  
  map <- ggplot()+
    geom_sf(data = basemap, fill = 'white')+
    geom_sf(data = watershed_sf, fill = 'transparent', color = 'firebrick', size = 0.01, linetype = 'dotted')+
    geom_sf(data = lake_sf, fill = ' light blue', color = 'grey', alpha = 0.5)+
    geom_text(data = labels_df, aes(X, Y, label = label), colour = "black", nudge_x = 1,size = 2)+
    lims(x = c(map_bbox[1],map_bbox[3]),y = c(map_bbox[2],map_bbox[4]))+
    theme_bw()+
    labs(title = title)
  
  return(map)
  
}

## mapping function for sw and wq - shape aesthetic specified

map_sites_sw_wq <- function(watershed_sf, lake_sf, sites_sf, basemap, map_bbox, title = '', shape_col, color_col){   
  
  map <- ggplot()+
    geom_sf(data = basemap, fill = 'white')+
    geom_sf(data = watershed_sf, fill = 'transparent', color = 'firebrick', size = 0.01, linetype = 'dotted')+
    geom_sf(data = lake_sf, fill = ' light blue', color = 'grey', alpha = 0.5)+ 
    geom_sf(data = sites_sf,
            aes(geometry = geometry, color = .data[[color_col]], shape = .data[[shape_col]]), size = 1)+
    lims(x = c(map_bbox[1],map_bbox[3]),y = c(map_bbox[2],map_bbox[4]))+
    theme_bw()+
    labs(title = title)
  return(map)
  
}

## mapping gw sites - no shape specified
map_dv_sites_gw <- function(watershed_sf, lake_sf, sites_sf, basemap, map_bbox, color_col, title = ''){   
  
  map <- ggplot()+
    geom_sf(data = basemap, fill = 'white')+
    geom_sf(data = watershed_sf, fill = 'transparent', color = 'firebrick', size = 0.01, linetype = 'dotted')+
    geom_sf(data = lake_sf, fill = ' light blue', color = 'grey', alpha = 0.5)+ 
    geom_sf(data = sites_sf,
            aes(geometry = geometry, color = .data[[color_col]]), size = 1)+
    lims(x = c(map_bbox[1],map_bbox[3]),y = c(map_bbox[2],map_bbox[4]))+
    theme_bw()+
    labs(title = title)+
    scale_color_gradient(low = 'grey',high = 'black')
  
  return(map)
  
}


# Maps outputs ------------------------------------------------------------


# mapping qw sites

## transform into sf obj
wq_sites_sf <- wq_sites %>% st_as_sf(coords = c('lon','lat'), crs = st_crs(p3_saline_lakes_sf))


map_sites_sw_wq(watershed_sf = p2_lake_watersheds_dissolved, lake_sf = p3_saline_lakes_sf, sites_sf = wq_sites_sf,
                basemap = us_sf,map_bbox = map_bbox, title = '', shape_col = 'ProviderName',
                color_col = 'ResolvedMonitoringLocationTypeName')



### mapping sw sites 

sw_sites_sf_00060 <- nwis_dv_sw_data %>%
  select(-contains(c('00065','..2..'))) %>% 
  ## removing where both valid measurements of 00060 are na
  filter(!(is.na(X_00060_00003) & is.na(X_00060_00011))) %>%
  #  filter(stream_order_category != "not along SO 3+") %>% 
  mutate(dateTime = as.Date(dateTime)) %>% 
  group_by(site_no, lake_w_state,lon,lat, stream_order_category) %>% 
  summarize(nmbr_observations = n(),
            min_date = min(dateTime),
            max_date = max(dateTime)) %>% 
  st_as_sf(coords = c('lon','lat'), crs = st_crs(p3_saline_lakes_sf)) %>% arrange(desc(nmbr_observations))



map_sites_sw_wq(watershed_sf = p2_lake_watersheds_dissolved, lake_sf = p3_saline_lakes_sf,
                sites_sf = sw_sites_sf_00060, basemap = us_sf, 
                map_bbox = map_bbox, title = '', shape_col = 'stream_order_category',
                color_col = 'nmbr_observations')



### mapping gw sites

gw_sites_sf_72019 <- nwis_dv_gw_data %>%
  select(-contains(c('..2..'))) %>% 
  ## removing where both valid measurements of 00060 are na
  filter(!(is.na(X_72019_00003) & is.na(X_72019_00002) & is.na(X_72019_00003) & is.na(X_72019_00008) & is.na(X_72019_31200))) %>% 
  #  filter(stream_order_category != "not along SO 3+") %>% 
  mutate(dateTime = as.Date(dateTime)) %>% 
  group_by(site_no, lake_w_state, lon, lat) %>% 
  summarize(nmbr_observations = n(),
            min_date = min(dateTime),
            max_date = max(dateTime)) %>% 
  #  ungroup() %>% 
  mutate(observations_classified = case_when(nmbr_observations < 100 ~ '<100',
                                             nmbr_observations >= 100 & nmbr_observations < 500 ~ '100 - 500',
                                             nmbr_observations >= 500 & nmbr_observations < 2000 ~ '500 - 2000',
                                             nmbr_observations >= 2000 & nmbr_observations < 5000 ~ '2000 - 5000',
                                             nmbr_observations >= 5000 & nmbr_observations < 8000 ~ '5000 - 8000',
                                             TRUE ~ '> 8000')) %>% 
  st_as_sf(coords = c('lon','lat'), crs = st_crs(p3_saline_lakes_sf))


map_dv_sites_gw <- map_dv_sites_gw(watershed_sf = p2_lake_watersheds_dissolved,
                            lake_sf = p3_saline_lakes_sf,
                            sites_sf = gw_sites_sf_72019,
                            basemap = us_sf, 
                            map_bbox = map_bbox, title = '',
                            color_col = 'nmbr_observations')
