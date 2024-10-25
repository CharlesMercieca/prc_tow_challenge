library(tidyverse)
library(nanoparquet)
library(pillar)

directory <- "D:/prc_data/flights/"

#Wind Functions
velocity <- function(uo, vo){
  return(sqrt(uo**2 + vo**2))
}

direction <- function(uo, vo){
  return(180 + (180/pi) * atan2(uo, vo))
}

headwind_component <- function(speed, angle){
  return(speed*cos(angle * (pi/180)))
}

#do filtering based on times.
filter_table_challenge <- read_csv('challenge_set.csv') %>% 
  select(flight_id, actual_offblock_time, taxiout_time, arrival_time) %>% 
  mutate(takeoff_time = actual_offblock_time + lubridate::minutes(taxiout_time),
         climb_cutoff_time = takeoff_time + lubridate::minutes(40))

filter_table_submission <- read_csv('final_submission_set.csv') %>% 
  select(flight_id, actual_offblock_time, taxiout_time, arrival_time) %>% 
  mutate(takeoff_time = actual_offblock_time + lubridate::minutes(taxiout_time),
         climb_cutoff_time = takeoff_time + lubridate::minutes(40))

filter_table <- bind_rows(filter_table_challenge, filter_table_submission)

#run them in for loop for each flight id
final_df <- data.frame()

for (file in list.files(directory)){
  print(file)
  data <- read_parquet(paste0(directory, file))
  
  out <- data %>% 
    inner_join(filter_table, join_by(flight_id, timestamp >= takeoff_time, timestamp <= climb_cutoff_time)) %>% 
    mutate(velocity = velocity(u_component_of_wind, v_component_of_wind),
           direction = direction(u_component_of_wind, v_component_of_wind),
           headwind_component = headwind_component(velocity, track-direction),
           tas = groundspeed-headwind_component,
           fl = case_when(altitude >=0 & altitude <=500 ~ 00,
                        altitude > 500 & altitude <1000 ~ 05,
                        TRUE ~ floor(altitude/1000)*10)) %>% 
    filter(vertical_rate > 50) %>% 
    filter(vertical_rate < 5000) %>% 
    group_by(flight_id, fl) %>% 
    summarise(
              mean_vs = mean(vertical_rate, na.rm = T),
              mean_tas = mean(tas, na.rm = T),
              median_vs = median(vertical_rate, na.rm = T),
              median_tas = median(tas, na.rm = T),
              mean_temp = mean(temperature, na.rm=T),
              mean_sh = mean(specific_humidity, na.rm=T),
              obs = n()
              ) %>% 
    ungroup()
  
  final_df <- bind_rows(final_df, out)
}

#write output
final_df %>% 
  write_csv(paste0('climb_table_features_',
                   lubridate::today(),
                   '.csv'))

final_df %>% 
  mutate(fl = paste0("fl", fl)) %>% 
  pivot_wider(id_cols=flight_id, names_from = fl, values_from = mean_vs)
