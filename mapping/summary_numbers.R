
# libs --------------------------------------------------------------------
library(ggplot2)
library(tidyverse)
library(sf)
library(mapview)
library(lubridate)
library(maps)
library(ggrepel)

source('2_process/src/sites_along_waterbody.R')


# read in data  -----------------------------------------------------------

targets::tar_load(p4_nwis_dv_gw_data_rds)
targets::tar_load(p4_nwis_dv_sw_data_rds)
targets::tar_load(p2_nwis_dv_gw_data)
targets::tar_load(p2_nwis_dv_sw_data)
targets::tar_load(p3_saline_lakes_sf)
targets::tar_load(p2_lake_watersheds_dissolved)
targets::tar_load(p2_saline_lakes_sf)
targets::tar_load(p2_lake_tributaries)
targets::tar_load(p1_nwis_meas_sw_data)
targets::tar_load(p1_nwis_meas_gw_data)

#saline_lakes <- p3_saline_lakes_sf
#lake_watersheds <- p2_lake_watersheds_dissolved
saline_lakes <- st_read('mapping/saline_lakes.shp')
lake_watersheds <- st_read('mapping/watersheds.shp')

nwis_dv_gw_data <- readRDS(p4_nwis_dv_gw_data_rds)
nwis_dv_sw_data <- readRDS(p4_nwis_dv_sw_data_rds)
# nwis_dv_gw_data <- readRDS("mapping/p1_nwis_dv_gw_data")
# nwis_dv_sw_data <- readRDS("mapping/p1_nwis_dv_sw_data.rds")

wq_data <- readRDS('mapping/harmonized_wqp_data_added_cols.rds')
wq_sites <- readRDS('mapping/harmonized_wqp_sites.rds') 

# summarize sw dv data ---------------------------------------------------------

p2_nwis_dv_sw_data %>% dim()
p2_nwis_dv_gw_data %>% dim()

sw_lake_totals <- p2_nwis_dv_sw_data %>% 
  select(-contains('cd')) %>% 
  select(lake_w_state, site_no, X_00060_00003) %>%
  filter(!is.na(X_00060_00003)) %>% 
  group_by(lake_w_state, site_no) %>%
  summarise(nbr_obs = n()) %>% 
  arrange(desc(nbr_obs))

sw_lake_totals$lake_w_state %>% unique()
# [1] "Great Salt Lake,UT" "Pyramid Lake,NV"    "Carson Lake,NV"     "Sevier Lake,UT"     "Owens Lake,CA"      "Walker Lake,NV"    
# [7] "Mono Lake,CA"       "Malheur Lake,OR" 

sw_lake_totals$nbr_obs %>% sum() 
# 1054172 --> This is the total number of sw observations for stream order 3 + and lake

sw_lake_totals$site_no %>% unique() %>% length # 175 


# summarize gw dv data -------------------------------------------------------

library(dplyr)

p2_nwis_dv_gw_data %>% head()

gw_lake_totals <- nwis_dv_gw_data %>% 
  select(-contains('cd')) %>% 
  filter(!(is.na(X_72019_00003) & is.na(X_72019_00002) & is.na(X_72019_00001) & is.na(X_72019_00008) & is.na(X_72019_31200))) %>% 
  mutate(rowSums_measurements = rowSums(across(starts_with("X_")), na.rm = T)) %>% 
  group_by(lake_w_state, site_no) %>%
  summarise(nbr_obs = n()) %>% 
  arrange(desc(nbr_obs))

gw_lake_totals$lake_w_state %>% unique()

gw_lake_totals$nbr_obs %>% sum()
# 181856

gw_lake_totals$site_no %>% unique() %>% length

p2_nwis_dv_sw_data %>% select(lake_w_state, site_no) %>% distinct() %>% group_by(lake_w_state) %>% summarize(n()) %>% arrange(desc(`n()`))

p2_nwis_dv_gw_data %>% select(lake_w_state, site_no) %>% distinct() %>% group_by(lake_w_state) %>% summarize(n()) %>% arrange(desc(`n()`))





# field measurement stats - SW -------------------------------------------------

p1_nwis_meas_sw_data %>% dim()

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

## wrangling
{
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
  mutate(year_gp = ifelse(year > 2010, 'After 2010','2010 or before')) %>% 
  ungroup()

sw_fm <- sw_meas_per_year %>% 
  group_by(site_no, lake_w_state,  stream_order) %>% 
  summarise(nmbr_observations = sum(nmbr_observations_yr)) %>%
  arrange(desc(nmbr_observations))
}

total_sw_fm_per_lake <- sw_meas_per_year %>%
  filter(!grepl('Not',stream_order)) %>%
  group_by(lake_w_state, year_gp) %>%
  summarise(total_number_of_measurements = n())

total_sw_fm_per_lake


# field measurements stats - gw  ------------------------------------------


# These are random gw samples taken 
p1_nwis_meas_gw_data %>% dim()
p1_nwis_meas_gw_data$lev_dt %>% max()
Lakes_gw_meas_data <- is.na(p1_nwis_meas_gw_data$lev_dt)
gw_meas_data <- p1_nwis_meas_gw_data %>% filter(!Lakes_gw_meas_data)

gw_meas_data$lev_dt %>% max()

{
gw_meas_per_year <- gw_meas_data %>%
  select(site_no,lake_w_state,lev_va, lev_dt) %>% 
  filter(!is.na(lev_va)) %>% 
  mutate(lev_dt = as.Date(lev_dt),
         year = year(lev_dt),
         month = month(lev_dt)) %>% 
  group_by(site_no, lake_w_state, year) %>% 
  summarise(nmbr_observations_yr = n()) %>% 
  filter(nmbr_observations_yr > 3) %>% 
  mutate(year_gp = ifelse(year > 2010, 'After 2010','2010 or before')) %>% 
  arrange(nmbr_observations_yr) %>% ungroup()

gw_fm <- gw_meas_per_year %>% 
  group_by(site_no, lake_w_state) %>% 
  summarise(nmbr_observations = sum(nmbr_observations_yr)) %>%
  arrange(desc(nmbr_observations))
}

total_gw_fm_per_lake <- gw_meas_per_year %>%
  group_by(lake_w_state, year_gp) %>%
  summarise(total_number_of_measurements = n())

total_gw_fm_per_lake

# summarize wq data -------------------------------------------------------

wq_data %>% filter(!is.na(MonitoringLocationIdentifier)) %>% View()
%>% pull(lake_w_state) %>% unique()


## Clean table first
cleaned_wq_data <- wq_data %>% 
  filter(flag_missing_result == FALSE) %>%
  select(MonitoringLocationIdentifier, ActivityStartDate, CharacteristicName, stream_order_category) %>% 
  mutate(ActivityStartDate = as.Date(ActivityStartDate),
         Year = year(ActivityStartDate),
         Month = month(ActivityStartDate))

cleaned_wq_data %>%
  select(MonitoringLocationIdentifier, stream_order_category) %>%
  distinct() %>% 
  group_by(stream_order_category) %>%
  summarise(n()) 

cleaned_wq_data %>%
  select(MonitoringLocationIdentifier) %>% unique() %>% nrow()


sites_above_data_coverage_threshold <- cleaned_wq_data %>% 
  ## Create new Year col and month col to then gather different year and month coverage 
  group_by(MonitoringLocationIdentifier, CharacteristicName, Year) %>% 
  ## Summarizations related to date range, obr of obs,  
  summarize(nbr_observations = n()) %>% 
  filter(nbr_observations >= 3) %>% arrange(nbr_observations) %>%
  pull(MonitoringLocationIdentifier) %>% unique()

sites_per_stream_order <- cleaned_wq_data %>%
  filter(MonitoringLocationIdentifier %in% sites_above_data_coverage_threshold) %>%
  select(MonitoringLocationIdentifier, stream_order_category) %>% 
  distinct() %>% 
  group_by(stream_order_category) %>% 
  summarize(n())




summarized_wqp_data <- cleaned_wq_data %>%
  filter(MonitoringLocationIdentifier %in% sites_above_data_coverage_threshold) %>% ## this only removed about 20,000 observations
#  filter(!grepl('Not',stream_order_category)) %>% 
  ## Create year col and month col to then gather different year and month coverage 
  group_by(MonitoringLocationIdentifier) %>% 
  ## Summarizations related to date range, obr of obs,  
  summarize(min_date = min(ActivityStartDate),
            # mean_date = median(ActivityStartDate),
            max_date = max(ActivityStartDate),
            nbr_observations = n(),
            wq_data_coverage = paste0(unique(CharacteristicName), collapse = ', '),
            years_coverage = paste0(unique(Year), collapse = ', '), 
            months_coverage = paste0(unique(Month), collapse = ', ')) %>% 
  arrange(desc(nbr_observations)) %>% 
  ## Create new col with categories of observations 
  mutate(nbr_obs_classes = ifelse(nbr_observations <= 10,'<10',
                                  ifelse(nbr_observations > 10 & nbr_observations <= 100,'10-100',
                                         ifelse(nbr_observations > 100 & nbr_observations <= 1000,'100-1,000','>1,000')))) %>%
  mutate(nbr_obs_classes = factor(nbr_obs_classes, c('<10','10-100','100-1,000','>1,000'))) %>% 
  ungroup()


summarized_wqp_data %>% group_by(stream_order_category) %>% summarize(n())

summarized_wqp_data$nbr_observations %>% sum() ## 411,602 obs

summarized_wqp_data$MonitoringLocationIdentifier %>% length() # 1212 sites 


# OLD CODE ----------------------------------------------------------------

# obs_completion_00060 <- sw_lake_totals %>%
#   st_drop_geometry() %>%
#   group_by(nbr_obs, lake_w_state) %>%
#   select(lake_w_state, rowSums_measurements) %>%
#   summarise(nbr_obs = n()) %>% arrange(desc(`n()`)) %>%
#   filter(nbr_obs == 8367) 
# 
# obs_completion_00060  <- gw_lake_totals %>% 
#   st_drop_geometry() %>%
#   group_by(nmbr_observations, lake_w_state) %>%
#   summarise(n()) %>% arrange(desc(`n()`)) %>%
#   filter(nbr_obs == 8367)
