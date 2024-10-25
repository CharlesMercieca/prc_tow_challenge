library(bundle)
library(lightgbm)
library(bonsai)

#process prediction data

challenge <- read_csv('data/final_submission_set.csv')

specific_energy <-read_csv("data/climb_features_processed2024-10-19.csv") %>%
  mutate(point = paste0('p', point)) %>%
  pivot_wider(id_cols = flight_id, names_from = point, values_from = c(altitude, speed, specific_energy))

ctf <- read_csv("data/climb_table_features_2024-10-19.csv") %>%
  filter(fl >= 0 & fl <=360) %>%
  mutate(fl = paste0('fl', fl)) %>%
  pivot_wider(id_cols = flight_id, names_from =fl, values_from = c(median_vs, median_tas, mean_temp, mean_sh))

aircraft_type <- read_csv('aircraft_type.csv')

auc_feature <- read_csv('data/auc_feature.csv')

sched_freq <- challenge %>%
  group_by(airline, aircraft_type, adep, ades) %>%
  tally() %>%
  rename('sched_freq'=n)

challenge <- challenge %>%
  left_join(specific_energy) %>%
  left_join(ctf) %>%
  inner_join(aircraft_type) %>%
  left_join(sched_freq) %>% 
  left_join(auc_feature)


#read in adep/ades lumping
adep_lookup <- read_csv('data/adep_lumped.csv') %>% 
  pull(adep_lumped)
ades_lookup <- read_csv('data/ades_lumped.csv') %>% 
  pull(ades_lumped)

data_cleaned <- challenge %>% 
  mutate(month = lubridate::month(date),
         off_block_hour = lubridate::hour(actual_offblock_time),
         arrival_hour = lubridate::hour(arrival_time),
         adep = as.factor(adep),
         ades = as.factor(ades),
         aircraft_type=as.factor(aircraft_type),
         airline=as.factor(airline),
         log_tow = log(tow),
         doy = lubridate::yday(date),
         dow = lubridate::wday(date),
         #adep_lumped = as.factor(if_else(adep %in% adep_lookup, adep, 'Other')),
         #ades_lumped = as.factor(if_else(adep %in% ades_lookup, ades, 'Other')),
         adep_lumped = fct_lump(adep, n=150),
         ades_lumped = fct_lump(ades, n=150),
         #time features
         wtc=as.factor(wtc),
         country_code_adep = as.factor(country_code_adep),
         country_code_ades = as.factor(country_code_ades)
  )

#load saved model
final_lgbm <- readRDS("butchered_final_lgbm.rds") %>% 
  unbundle()

predict(final_lgbm, data_cleaned) %>% 
  bind_cols(data_cleaned) %>% 
  select(flight_id, .pred) %>% 
  rename(tow=.pred) %>% 
  write_csv('team_affectionate_bridge_v6_89846913-3d30-491a-8da9-cea6b3310a30.csv')
