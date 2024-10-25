library(tidyverse)
library(nanoparquet)
library(pillar)

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

vertical_profile_features <- function(df){

  mean_vs <- df %>%
    pull(vertical_rate) %>% 
    mean(na.rm=T)
  
  #auc feature
  sqrt_auc <- tryCatch(
    {
      df <- df %>% 
        filter(groundspeed > 100)

              auc <- flux::auc(df$timestamp, df$altitude)
      
      tibble(sqrt_auc = sqrt(auc))},
    error = function(e){
      tibble(sqrt_auc = NA)
    }
  )
  
  return(tibble(mean_vs= mean_vs, sqrt_auc))
}

directory <- "D:/prc_data/flights/"
out_directory <- "D:/prc_data/processed_vertical_new"

for (file in list.files(directory)){
  print(file)
  data <- read_parquet(paste0(directory, file))
  
  climb_out <- data %>% 
    inner_join(filter_table, join_by(flight_id, timestamp >= takeoff_time, timestamp <= climb_cutoff_time)) %>% 
    group_by(flight_id) %>% 
    group_modify(~suppressMessages(vertical_profile_features(.x))) %>% 
    ungroup()
  
  flight <- data %>% 
    inner_join(filter_table, join_by(flight_id, timestamp >= takeoff_time, timestamp <= arrival_time))%>% 
    group_by(flight_id) %>% 
    summarise(max_alt = max(altitude, na.rm=T),
              max_vs = max(vertical_rate, na.rm=T))
  
  out <- left_join(climb_out, flight, by ='flight_id')
  
  write_csv(out, paste0(out_directory, "/processed_", str_replace(file, ".parquet", ".csv")))
  print(paste("Wrote: ", paste0(out_directory, "processed_", str_replace(file, ".parquet", ".csv"))))
  
}


#unify day chunks into 1 DF

csv_files <- list.files(out_directory , pattern = "\\.csv$", full.names = TRUE)

# Read each CSV file and store them in a list
csv_list <- lapply(csv_files, read.csv)

# Combine all the dataframes into one using bind_rows
combined_df <- bind_rows(csv_list)

write_csv(combined_df, 'auc_feature.csv')
