
# libs --------------------------------------------------------------------
library(ggplot2)
library(tidyverse)
library(sf)
library(mapview)
library(maps)
library(ggrepel)

# read in data  -----------------------------------------------------------

## target load for local pipeline - IGNORE
targets::tar_load(p4_nwis_dv_gw_data_rds)
targets::tar_load(p4_nwis_dv_sw_data_rds)
targets::tar_load(p3_saline_lakes_sf)
targets::tar_load(p2_lake_watersheds_dissolved)
targets::tar_load(p2_saline_lakes_sf)
targets::tar_load(p2_lake_tributaries)
targets::tar_load(p1_nwis_meas_sw_data)
targets::tar_load(p1_nwis_meas_gw_data)
## --

saline_lakes <- st_read('saline_lakes.shp')
lake_watersheds <- st_read('watersheds.shp')

nwis_dv_gw_data <- readRDS("p1_nwis_dv_gw_data.rds")
nwis_dv_sw_data <- readRDS("p1_nwis_dv_sw_data.rds")

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

labels_df <- saline_lakes %>%
  mutate(label = gsub('Lake: ','',label)) %>%
  select(label, X, Y) %>% st_drop_geometry()

map_bbox <- st_bbox(lake_watersheds)

# map fun -----------------------------------------------------------------

## general map that includes, lakes, labels
general_map <- function(watershed_sf, lake_sf, labels_df, basemap, map_bbox, title = 'Saline Lakes and Watersheds'){   

   map <- ggplot()+
    geom_sf(data = basemap, fill = 'white', color = 'grey', alpha = 0.1)+
    geom_sf(data = watershed_sf, fill = 'transparent', color = 'firebrick', size = 0.01, linetype = 'dotted')+
    geom_sf(data = lake_sf, fill = ' light blue', color = 'grey', alpha = 0.5)+
    ggrepel::geom_text_repel(data = labels_df, aes(X, Y, label = label),colour = "black",
                             size = 3, nudge_y = 0.1, nudge_x = 0.15,
                             segment.colour="black", min.segment.length = 1.5)+
    lims(x = c(map_bbox[1],map_bbox[3]),y = c(map_bbox[2],map_bbox[4]))+
    theme_classic()+
    labs(title = title)+
     theme(plot.title = element_text(size = 10, face= 'bold'),
           legend.text = element_text (size = 7),
           legend.title = element_text (size = 9),
           axis.title.x = element_blank(),
           axis.title.y = element_blank()
    )+
    guides(fill = guide_colorsteps(direction = 'horizontal', title.position = 'bottom'))
  
  return(map)
  
}

## mapping function for sw and wq - shape aesthetic specified

map_sites_sw_wq <- function(watershed_sf, lake_sf, sites_sf, basemap, map_bbox, title = '', shape_col, color_col){   
  
  map <- ggplot()+
    geom_sf(data = basemap, fill = 'white', color = 'grey', alpha = 0.1)+
    geom_sf(data = watershed_sf, fill = 'transparent', color = 'firebrick', size = 0.01, linetype = 'dotted')+
    geom_sf(data = lake_sf, fill = ' light blue', color = 'grey', alpha = 0.5)+ 
    geom_sf(data = sites_sf,
            aes(geometry = geometry, color = .data[[color_col]], shape = .data[[shape_col]]), size = 1)+
    lims(x = c(map_bbox[1],map_bbox[3]),y = c(map_bbox[2],map_bbox[4]))+
    theme_classic()+
    scale_color_steps()+
    labs(title = title)+
    theme(plot.title = element_text(size = 10, face= 'bold'),
          legend.text = element_text (size = 7),
          legend.title = element_text (size = 9),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          legend.position = 'bottom'
    )
  
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
    theme_classic()+
    labs(title = title)+
    scale_color_steps(low = 'orange', high = 'firebrick')+
    theme(plot.title = element_text(size = 10, face= 'bold'),
          legend.text = element_text (size = 7),
          legend.title = element_text (size = 9),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          legend.position = 'bottom')+
    guides(color = guide_colorsteps(direction = 'horizontal', title.position = 'top'),
           shape = guide_legend(direction = 'horizontal', title.position = 'top'))
  return(map)
  
}



# General map with labels ------------------------------------------------------------

gen_map <- general_map(watershed_sf = lake_watersheds,
            lake_sf = saline_lakes,
            labels_df = labels_df,
            basemap = us_sf,
            map_bbox = map_bbox,
            title = 'Focal Saline Lakes and Watersheds in the Great Basin')


ggsave(filename = 'gen_map.png',
       device= 'png',
       plot =gen_map,
       path = 'mapping/')

# Site maps outputs ------------------------------------------------------------


#### mapping sw sites #### 

sw_sites_sf_00060 <- nwis_dv_sw_data %>%
  select(-contains(c('00065','..2..'))) %>% 
  ## removing where both valid measurements of 00060 are na
  filter(!(is.na(X_00060_00003) & is.na(X_00060_00011))) %>%
  ## NOTE - filtering out stream order < 3 and recoded for graph purposes
  filter(stream_order_category != "not along SO 3+") %>%
  mutate(stream_order_category = recode(stream_order_category,
                                        "along SO 3+" = 'Along stream',
                                        "along lake" = 'Along lake')) %>% 
  mutate(dateTime = as.Date(dateTime)) %>% 
  group_by(site_no, lake_w_state,lon,lat, stream_order_category) %>% 
  summarize(nmbr_observations = n(),
            min_date = min(dateTime),
            max_date = max(dateTime)) %>% 
  st_as_sf(coords = c('lon','lat'), crs = st_crs(saline_lakes)) %>% arrange(desc(nmbr_observations)) 
  
sw_data_map <- map_sites_sw_wq(watershed_sf = lake_watersheds, lake_sf = saline_lakes,
                sites_sf = sw_sites_sf_00060, basemap = us_sf, 
                map_bbox = map_bbox, title = 'Active USGS-NWIS surface water sites (2000-2022)',
                shape_col = 'stream_order_category',color_col = 'nmbr_observations')+
  labs(color = 'Number of observations at gage site', shape = 'Waterbody type')+
  guides(color = guide_colorsteps(direction = 'horizontal', title.position = 'top'),
         shape = guide_legend(direction = 'horizontal', title.position = 'top'))
  
  
sw_data_map

ggsave(filename = 'sw_data_map.png',
       device= 'png',
       plot =sw_data_map,
       path = 'mapping/')

#### mapping gw sites ####

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
  ## adding col for categorizing obser nmbrs
  mutate(observations_classified = case_when(nmbr_observations < 100 ~ '<100',
                                             nmbr_observations >= 100 & nmbr_observations < 500 ~ '100 - 500',
                                             nmbr_observations >= 500 & nmbr_observations < 2000 ~ '500 - 2000',
                                             nmbr_observations >= 2000 & nmbr_observations < 5000 ~ '2000 - 5000',
                                             nmbr_observations >= 5000 & nmbr_observations < 8000 ~ '5000 - 8000',
                                             TRUE ~ '> 8000')) %>% 
  st_as_sf(coords = c('lon','lat'), crs = st_crs(saline_lakes))

gw_data_map <- map_dv_sites_gw(watershed_sf = lake_watersheds,lake_sf = saline_lakes,
                sites_sf = gw_sites_sf_72019,
                basemap = us_sf, 
                map_bbox = map_bbox,
                title = 'Active USGS-NWIS groudwater sites (2000-2022)',
                color_col = 'nmbr_observations')+
  labs(color = 'Number of observations at gage site')

  
ggsave(filename = 'gw_data_map.png',
       device= 'png',
       plot =gw_data_map,
       path = 'mapping/')



#### mapping qw sites ####

## transform into sf obj

wq_sites_sf %>% dim()

## Creating this because ruby and franklin's tributaries are not directly attaining the wetland and we can keep this date point
ruby_franklin_wq_sites <- c('21NEV1_WQX-NV10-007-T-005','21NEV1_WQX-NV10-007-T-001',
                            'USGS-400751115313001','USGS-400450115303401',
                            'USGS-400302115294201')

wq_sites_sf <- wq_sites %>%
  st_as_sf(coords = c('lon','lat'), crs = st_crs(saline_lakes))%>%
#  mutate(stream_order_category = ifelse(MonitoringLocationIdentifier %in% ruby_franklin_sites,'Save',stream_order_category)) %>%
  filter(stream_order_category != "Not along SO 3+ or saline lake")

wq_sites_map <- map_sites_sw_wq(watershed_sf = lake_watersheds, lake_sf = saline_lakes, sites_sf = wq_sites_sf,
                                basemap = us_sf,map_bbox = map_bbox,
                                title = 'Active water quality sites (2000-2022) by Provider',
                                shape_col = 'ProviderName',
                                color_col = 'ResolvedMonitoringLocationTypeName')+
  labs(color = 'Waterbody type', shape = 'Provider name')+
  scale_color_brewer(palette="Accent")+
  guides(color = guide_legend(direction = 'horizontal', title.position = 'top'),
         shape = guide_legend(direction = 'horizontal', title.position = 'top')) ## subbing diff color to supplement

wq_sites_map

ggsave(filename = 'wq_sites.png',
       device= 'png',
       plot =wq_sites_map,
       path = 'mapping/')



#### mapping qw data ####
sites_above_data_coverage_threshold <- wq_data %>% 
  select(MonitoringLocationIdentifier, ActivityStartDate,
         CharacteristicName, ResultMeasureValue) %>%
  ## Create new Year col and month col to then gather different year and month coverage 
  mutate(ActivityStartDate = as.Date(ActivityStartDate),
         Year = year(ActivityStartDate)) %>% 
  group_by(MonitoringLocationIdentifier, CharacteristicName, Year) %>% 
  ## Summarizations related to date range, obr of obs,  
  summarize(nbr_observations = n()) %>% 
  filter(nbr_observations > 3) %>% arrange(nbr_observations) %>% pull(MonitoringLocationIdentifier) %>% unique()

summarized_wqp_data <- wq_data %>%
  filter(MonitoringLocationIdentifier %in% sites_above_data_coverage_threshold) %>% ## this only removed about 20,000 observations
  filter(!grepl('Not',stream_order_category)) %>% 
  select(MonitoringLocationIdentifier, ActivityStartDate, CharacteristicName, ResultMeasureValue) %>% 
  ## Create year col and month col to then gather different year and month coverage 
  mutate(ActivityStartDate = as.Date(ActivityStartDate),
         Year = year(ActivityStartDate),
         Month = month(ActivityStartDate)) %>% 
  group_by(MonitoringLocationIdentifier, CharacteristicName) %>% 
  ## Summarizations related to date range, obr of obs,  
  summarize(min_date = min(ActivityStartDate),
            # mean_date = median(ActivityStartDate),
            max_date = max(ActivityStartDate),
            nbr_observations = n(),
            years_converage = paste0(unique(Year), collapse = ', '), 
            months_coverage = paste0(unique(Month), collapse = ', '),
            mean_value = mean(ResultMeasureValue)) %>% 
  arrange(desc(nbr_observations)) %>% 
  ## Create new col with categories of observations 
  mutate(nbr_obs_classes = ifelse(nbr_observations <= 10,'<10',
                                  ifelse(nbr_observations > 10 & nbr_observations <= 100,'10-100',
                                         ifelse(nbr_observations > 100 & nbr_observations <= 1000,'100-1,000','>1,000')))) %>%
  mutate(nbr_obs_classes = factor(nbr_obs_classes, c('<10','10-100','100-1,000','>1,000'))) %>% 
  ungroup()

## Join to spatial file
summarized_wqp_data_sf <- summarized_wqp_data %>% 
  left_join(wq_sites_sf[,c('MonitoringLocationIdentifier','geometry')] %>%
              distinct(),
            by = 'MonitoringLocationIdentifier') %>%
  st_as_sf() 

## Generate Map 
map_wq_data_availability <- ggplot()+
  geom_sf(data = us_sf, fill = 'white')+
  geom_sf(data = lake_watersheds, fill = 'transparent', color = 'firebrick', size = 0.01, linetype = 'dotted')+
  geom_sf(data = saline_lakes, fill = ' light blue', color = 'grey', alpha = 0.5)+
  geom_sf(data = summarized_wqp_data_sf,
          aes(geometry = geometry, color = nbr_obs_classes), size =0.4)+
  lims(x = c(bbox[1],bbox[3]),y = c(bbox[2],bbox[4]))+
  theme_classic()+
  theme(plot.title = element_text(size = 10, face= 'bold'),
        legend.text = element_text (size = 7),
        legend.title = element_text (size = 9),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = 'bottom'
  )+
  labs(title = 'Active water quality sites (2000-2022) by number of observations',
       color = 'Number of observations - grouped')+
  scale_colour_brewer(palette = 'PRGn')+
  guides(color = guide_legend(direction = 'horizontal', title.position = 'top'),
         shape = guide_legend(direction = 'horizontal', title.position = 'top'))

map_wq_data_availability

ggsave(filename = 'wq_data.png',
       device= 'png',
       plot =map_wq_data_availability,
       path = 'mapping/')


map_wq_data_availability

### Field Meas #### 

Lakes_wo_meas_data <- is.na(p1_nwis_meas_sw_data$measurement_dt)

sw_meas_data <- p1_nwis_meas_sw_data %>% filter(!Lakes_wo_meas_data)


### Commenting out to avoid rerun

# meas_sites_along_streams <- sites_along_waterbody(sw_fm %>% st_as_sf() %>% select(site_no),
#                       p2_lake_tributaries,
#                       lake_waterbody = FALSE)
# 
# meas_sites_along_lake <- sites_along_waterbody(sw_fm %>% st_as_sf() %>% select(site_no),
#                                                   p2_saline_lakes_sf,
#                                                   lake_waterbody = TRUE)


sw_meas_data$measurement_dt %>% max()
sw_meas_data$measurement_dt %>% max()

sw_meas_per_year <- sw_meas_data %>%
  mutate(stream_order = case_when(site_no %in% meas_sites_along_streams ~'along streams SO 3+',
                                      site_no %in% meas_sites_along_lake ~ 'along lake',
                                      ## Saving datapoint around Franklin because tributaries are not very distinguished and it would eliminiate a location unnecessarily  
                                      lake_w_state %in% c('Franklin Lake,NV','Ruby Lake,NV') ~ 'in Franklin & Ruby Lake wetland',
                                      TRUE ~ 'Not along tributary or lake')) %>% 
  select(site_no,lake_w_state,discharge_va, gage_height_va, measurement_dt, stream_order) %>% 
  filter(!(is.na(discharge_va) & is.na(gage_height_va))) %>% 
  mutate(year = year(measurement_dt), month = month(measurement_dt)) %>% 
  group_by(site_no, lake_w_state, stream_order, year) %>% 
  summarise(nmbr_observations_yr = n()) %>%
  filter(nmbr_observations_yr > 3) %>% 
  ungroup()

sw_fm <- sw_meas_per_year %>% 
  group_by(site_no, lake_w_state,  stream_order) %>% 
  summarise(nmbr_observations = sum(nmbr_observations_yr)) %>%
  arrange(desc(nmbr_observations)) %>%  
  left_join(., p2_site_in_watersheds_sf, by = 'site_no')

sw_meas_map <- ggplot()+
  geom_sf(data = us_sf, fill = 'white')+
  geom_sf(data = watershed_sf, fill = 'transparent', color = 'firebrick', size = 0.01, linetype = 'dotted')+
  geom_sf(data = saline_lakes, fill = ' light blue', color = 'grey', alpha = 0.5)+ 
  geom_sf(data = sw_fm %>% filter(!grepl('Not',stream_order_col)),aes(geometry = geometry, color = nmbr_observations), size = 1)+
  lims(x = c(map_bbox[1],map_bbox[3]),y = c(map_bbox[2],map_bbox[4]))+
  theme_classic()+
  scale_color_steps()+
  labs(title = 'USGS-NWIS surface water field measurements conducted between 2000-2022', 
       color = 'Number of observations at gage site')+
  theme(plot.title = element_text(size = 10, face= 'bold'),
        legend.text = element_text (size = 7),
        legend.title = element_text (size = 9),
        legend.position = 'bottom')+
  guides(color = guide_colorsteps(direction = 'horizontal', title.position = 'top'),
         shape = guide_legend(direction = 'horizontal', title.position = 'top'))

ggsave(filename = 'sw_meas_map.png',
       device= 'png',
       plot =sw_meas_map,
       path = 'mapping/')



#### gw field meas ####
gw_meas_per_year <- p1_nwis_meas_gw_data %>%
  select(site_no,lake_w_state,lev_va, lev_dt) %>% 
  filter(!is.na(lev_va)) %>% 
  mutate(lev_dt = as.Date(lev_dt),
         year = year(lev_dt),
         month = month(lev_dt)) %>% 
  group_by(site_no, lake_w_state, year) %>% 
  summarise(nmbr_observations_yr = n()) %>% 
  arrange(desc(nmbr_observations_yr)) %>% ungroup()

gw_fm <- meas_per_year %>%
  filter(nmbr_observations_yr > 3) %>% 
  ungroup() %>% 
  group_by(site_no, lake_w_state) %>% 
  summarise(nmbr_observations = sum(nmbr_observations_yr)) %>%
  arrange(desc(nmbr_observations)) %>%  
  left_join(., p2_site_in_watersheds_sf, by = 'site_no')

gw_meas_map <- ggplot()+
  geom_sf(data = us_sf, fill = 'white')+
  geom_sf(data = watershed_sf, fill = 'transparent', color = 'firebrick', size = 0.01, linetype = 'dotted')+
  geom_sf(data = saline_lakes, fill = ' light blue', color = 'grey', alpha = 0.5)+ 
  geom_sf(data = gw_fm,aes(geometry = geometry, color = nmbr_observations), size = 0.5)+
  lims(x = c(map_bbox[1],map_bbox[3]),y = c(map_bbox[2],map_bbox[4]))+
  theme_classic()+
  scale_color_steps()+
  labs(title = 'USGS-NWIS ground water field measurements conducted between 2000-2022',
       color = 'Number of observations at gage site')+
  theme(plot.title = element_text(size = 10, face= 'bold'),
        legend.text = element_text (size = 7),
        legend.title = element_text (size = 9),
        legend.position = 'bottom')+
  guides(color = guide_colorsteps(direction = 'horizontal', title.position = 'top'),
         shape = guide_legend(direction = 'horizontal', title.position = 'top'))

ggsave(filename = 'gw_meas_map.png',
       device= 'png',
       plot =gw_meas_map,
       path = 'mapping/')


