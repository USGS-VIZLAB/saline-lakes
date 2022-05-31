library(sf)
library(nhdplusTools)
library(dplyr)
library(stringr)

## CRS: keeping crs at 4326 for now 
selected_crs = 4326

## list of lakes
lakes_excel <- readxl::read_xlsx('Data/Lakes_list.xlsx', col_types = 'text')

## Turning lakes into SF obj
lakes <- lakes_excel %>% 
  ## note - lon comes first in st_as_sf() 
  st_as_sf(coords = c('Lon','Lat'), crs = 4326) %>% 
  rename(Point_geometry = geometry, lake = `Lake Ecosystem`) %>% 
  mutate(lake = str_to_title(lake)) %>% 
  mutate(lake_name_shrt = trimws(str_replace(lake, pattern = 'Lake', replacement = "")))

## Define temp dir in Data folder
nhdhr_dir <- file.path('Data', "nhdhr_lakes")

## Get huc08 for focal lakes and extract comids
huc8 <- get_huc8(AOI = lakes$Point_geometry)
huc8_comids <- substr(huc8$huc8, start = 1, stop = 4) %>% unique()

## nhdplustools
nhdplusTools::download_nhdplushr(nhdhr_dir, huc8_comids)

