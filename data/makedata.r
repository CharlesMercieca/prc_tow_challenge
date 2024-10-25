library(tidyverse)

challenge <- read_csv('challenge_set.csv')

mean_wt <- challenge %>%
  group_by(aircraft_type) %>%
  summarise(mean_type_wt=mean(tow))

specific_energy <-read_csv("climb_features_processed2024-10-19.csv") %>%
  mutate(point = paste0('p', point)) %>%
  pivot_wider(id_cols = flight_id, names_from = point, values_from = c(altitude, speed, specific_energy))

ctf <- read_csv("climb_table_features_2024-10-19.csv") %>%
  filter(fl >= 0 & fl <=360) %>%
  mutate(fl = paste0('fl', fl)) %>%
  pivot_wider(id_cols = flight_id, names_from =fl, values_from = c(median_vs, median_tas, mean_temp, mean_sh))

aircraft_type <- read_csv('aircraft_types.csv')%>%
  inner_join(mean_wt)

auc_feature <- read_csv('auc_feature.csv')

#time features
tf <- bind_cols(lubridate::cyclic_encoding(challenge$date, c('day', 'week', 'month')),
                lubridate::cyclic_encoding(challenge$actual_offblock_time, c('hour')),
                lubridate::cyclic_encoding(challenge$arrival_time, c('hour')))

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


#Create some features
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
         dow = as.factor(lubridate::wday(date)),
         adep_lumped = fct_lump(adep, n=150),
         ades_lumped = fct_lump(ades, n=150),
         #time features
         wtc=as.factor(wtc),
         #country_code_adep = as.factor(country_code_adep),
         #country_code_ades = as.factor(country_code_ades)
  )

## save airport labels
data_cleaned %>%
  group_by(adep_lumped)%>%
  tally() %>%
  select(adep_lumped) %>%
  write_csv('adep_lumped.csv')

data_cleaned %>%
  group_by(ades_lumped)%>%
  tally() %>%
  select(ades_lumped) %>%
  write_csv('ades_lumped.csv')

data_cleaned %>% 
  write_csv('data_cleaned.csv')
