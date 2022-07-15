library(targets)
library(xlsx)
tar_load(p1_get_lakes_huc8_sf)

p1_get_lakes_huc8_sf %>%
  st_drop_geometry() %>%
  as.data.frame() %>%
  distinct() %>%
  select(lake_w_state, Name, HUC8) %>%
  rename(`Saline lake` = lake_w_state, 
         `Subbasin name` = Name) %>%
  mutate(`Keep/discard` = "",
         Notes = "") %>%
  write.xlsx(file = "3_visualize/out/Subbasin_KeepDiscard.xlsx",
             sheetName = "Subbasins",
             col.names = T,
             row.names = F)
