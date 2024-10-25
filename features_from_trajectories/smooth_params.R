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

process_altitude_data <- function(data, interval_seconds = 30, df = 10, threshold = 15000) {
  tryCatch(
    {
      
  # Ensure data is sorted by timestamp
  data <- data %>% arrange(timestamp)
  
  # Convert timestamp to numeric (seconds since the epoch)
  time_numeric <- as.numeric(data$timestamp)
  
  # Fit a smoothing spline using smooth.spline
  spline_fit_alt <- smooth.spline(time_numeric, data$altitude, df = df)
  spline_fit_speed <- smooth.spline(time_numeric, data$tas, df = df)
  
  # Create a sequence of evenly spaced timestamps
  start_time <- floor_date(min(data$timestamp), unit = "seconds")
  end_time <- ceiling_date(max(data$timestamp), unit = "seconds")
  new_times <- seq(start_time, end_time, by = paste(interval_seconds, "secs"))
  
  # Predict altitude at new timestamps
  new_altitude <- predict(spline_fit_alt, as.numeric(new_times))$y
  new_speed <- predict(spline_fit_speed, as.numeric(new_times))$y
  
  threshold <- min(threshold, max(new_altitude))
  
  # Create and return the resampled dataframe
  result <- data.frame(
    timestamp = new_times,
    altitude = new_altitude,
    speed = new_speed
  )
  
  #standardize outputs
  threshold_index <- which(result$altitude >= threshold)[1]
  
  start_index <- max(1, threshold_index - 10)
  end_index <- min(nrow(result), threshold_index + 20)
  final_results <- result[start_index:end_index, ]
  
  return(final_results) },
  error = function(e){
    return(
      data.frame(
        timestamp = NA,
        altitude = NA,
        speed = NA))})
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
           tas = groundspeed-headwind_component) %>% 
    select(flight_id, timestamp, altitude, tas) %>% 
    drop_na() %>% 
    group_by(flight_id) %>% 
    group_modify(~ process_altitude_data(.x))%>% 
    group_by(flight_id) %>% 
    mutate(point = row_number()) %>%
    ungroup()
  
  final_df <- bind_rows(final_df, out)
}

#write output
final_df %>% 
  write_csv(paste0('climb_features_raw',
                   lubridate::today(),
                   '.csv'))


final_df %>% 
  mutate(speed_ms =  speed/1.944,
         altitude_m = altitude/3.281,
         kinetic_energy = (speed_ms**2)/ (2*9.81),
         specific_energy = kinetic_energy + altitude_m)%>% 
  write_csv(paste0('climb_features_processed',
                   lubridate::today(),
                   '.csv'))

hist(z$specific_energy)

z %>% group_by(flight_id) %>% summarise(se=sum(specific_energy)) %>% pull(se) %>% hist(breaks=100)
