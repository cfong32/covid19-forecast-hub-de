# Simple baseline forecast for COVID19 death numbers in Germany and Poland
# setwd("/home/johannes/Documents/Projects/fork_covid19-forecast-hub-de/code/baselines")
source("functions_kit-baseline.R") # read in helper functions
Sys.setlocale("LC_ALL", "en_US.utf8") # Linux
# Sys.setlocale("LC_ALL","English") # Windows

# select forecast_date for which to generate forecasts
forecast_date <- (Sys.Date() - 0:6)[weekdays(Sys.Date() - 0:6) == "Monday"] # latest Monday
last_obs_week <- MMWRweek::MMWRweek(forecast_date)$MMWRweek - 1

# Define which quantiles are to be stored:
q <- c(0.01, 0.025, 1:19/20, 0.975, 0.99)

# path where the covid19-forecast-hub-de repository is stored
path_hub <- "../.."


### Deaths

# read in incident and cumulative death data:
dat_death_inc_de <- read.csv(paste0(path_hub, "/data-truth/RKI/truth_RKI-Incident Deaths_Germany.csv"),
                    colClasses = c(date = "Date"), stringsAsFactors = FALSE)
dat_death_inc_pl <- read.csv(paste0(path_hub, "/data-truth/MZ/truth_MZ-Incident Deaths_Poland.csv"),
                           colClasses = c(date = "Date"), stringsAsFactors = FALSE)
dat_death_inc <- rbind(dat_death_inc_de, dat_death_inc_pl)

dat_death_cum_de <- read.csv(paste0(path_hub, "/data-truth/RKI/truth_RKI-Cumulative Deaths_Germany.csv"),
                    colClasses = c(date = "Date"), stringsAsFactors = FALSE)
dat_death_cum_pl <- read.csv(paste0(path_hub, "/data-truth/MZ/truth_MZ-Cumulative Deaths_Poland.csv"),
                           colClasses = c(date = "Date"), stringsAsFactors = FALSE)
dat_death_cum <- rbind(dat_death_cum_de, dat_death_cum_pl)

# check that truth data are up to date:
if(max(dat_death_inc$date) < forecast_date - 1) warning("Please update the covid19-forecast-hub-de repository.")

# handle weekdays and epidemic weeks:
dat_death_inc$weekday <- weekdays(dat_death_inc$date)
dat_death_inc$week <- MMWRweek::MMWRweek(dat_death_inc$date)$MMWRweek
dat_death_inc$year <- MMWRweek::MMWRweek(dat_death_inc$date)$MMWRyear

# aggregate to weekly data:
dat_death_inc_weekly <- aggregate(dat_death_inc[, c("value")],
                            by = list(week = dat_death_inc$week,
                                      year = dat_death_inc$year,
                                      location = dat_death_inc$location,
                                      location_name = dat_death_inc$location_name),
                            FUN = sum)
colnames(dat_death_inc_weekly)[5] <- "inc_death"

# add target_end_date variable:
target_end_dates <- aggregate(dat_death_inc[, c("date")],
                              by = list(week = dat_death_inc$week,
                                        year = dat_death_inc$year,
                                        location = dat_death_inc$location,
                                        location_name = dat_death_inc$location_name),
                              FUN = max)
colnames(target_end_dates)[5] <- "target_end_date"

dat_death_inc_weekly <- merge(dat_death_inc_weekly, target_end_dates,
                        by = c("week", "year", "location", "location_name"))


# put everything together:
dat_death_weekly <- merge(dat_death_inc_weekly, dat_death_cum,
                    by.x = c("target_end_date", "location", "location_name"),
                    by.y = c("date", "location", "location_name"))
colnames(dat_death_weekly)[colnames(dat_death_weekly) == "value"] <- "cum_death"


# generate forecasts for Germany:

death_forecasts_de <- NULL

# run through locations in Germany:
locations_de <- unique(dat_death_weekly$location)
locations_de <- locations_de[grepl("GM", locations_de)]

for(loc in locations_de){
  cat("Starting", loc, "\n")
  
  # put everything together:
  forecasts_location <- baseline_forecast(dat_weekly = dat_death_weekly, loc = loc,
                                          target = "death", forecast_date = forecast_date)
  
  # and add to large table:
  if(is.null(death_forecasts_de)){
    death_forecasts_de <- forecasts_location
  }else{
    death_forecasts_de <- rbind(death_forecasts_de, forecasts_location)
  }
}

if(!(all(weekdays(death_forecasts_de$target_end_date) == "Saturday"))){
  warning("target_end_days are not all Saturdays!")
} else{
  # store:
  write.csv(death_forecasts_de, file = paste0(path_hub, "/data-processed/KIT-baseline/", forecast_date, "-Germany-KIT-baseline.csv"), row.names = FALSE)
}

# Generate forecasts for Poland:

death_forecasts_pl <- NULL

# run through locations in Poland:
locations_pl <- unique(dat_death_weekly$location)
locations_pl <- locations_pl[grepl("PL", locations_pl)]

for(loc in locations_pl){
  cat("Starting", loc, "\n")
  
  # put everything together:
  forecasts_location <- baseline_forecast(dat_weekly = dat_death_weekly, loc = loc,
                                          target = "death", forecast_date = forecast_date)
  
  # and add to large table:
  if(is.null(death_forecasts_pl)){
    death_forecasts_pl <- forecasts_location
  }else{
    death_forecasts_pl <- rbind(death_forecasts_pl, forecasts_location)
  }
}

if(!(all(weekdays(death_forecasts_pl$target_end_date) == "Saturday"))){
  warning("target_end_days are not all Saturdays!")
} else{
  # store:
  write.csv(death_forecasts_pl, file = paste0(path_hub, "/data-processed/KIT-baseline/", forecast_date, "-Poland-KIT-baseline.csv"), row.names = FALSE)
}



### Cases

# read in incident and cumulative case data:
dat_case_inc_de <- read.csv(paste0(path_hub, "/data-truth/RKI/truth_RKI-Incident Cases_Germany.csv"),
                            colClasses = c(date = "Date"), stringsAsFactors = FALSE)
dat_case_inc_pl <- read.csv(paste0(path_hub, "/data-truth/MZ/truth_MZ-Incident Cases_Poland.csv"),
                            colClasses = c(date = "Date"), stringsAsFactors = FALSE)
dat_case_inc <- rbind(dat_case_inc_de, dat_case_inc_pl)

dat_cum <- read.csv(paste0(path_hub, "/data-truth/RKI/truth_RKI-Cumulative Cases_Germany.csv"),
                    colClasses = c(date = "Date"), stringsAsFactors = FALSE)
dat_cum_poland <- read.csv(paste0(path_hub, "/data-truth/MZ/truth_MZ-Cumulative Cases_Poland.csv"),
                           colClasses = c(date = "Date"), stringsAsFactors = FALSE)
dat_cum <- rbind(dat_cum, dat_cum_poland)

# check that truth data are up to date:
if(max(dat_case_inc$date) < forecast_date - 1) warning("Please update the covid19-forecast-hub-de repository.")

# handle weekdays and epidemic weeks:
dat_case_inc$weekday <- weekdays(dat_case_inc$date)
dat_case_inc$week <- MMWRweek::MMWRweek(dat_case_inc$date)$MMWRweek
dat_case_inc$year <- MMWRweek::MMWRweek(dat_case_inc$date)$MMWRyear

# aggregate to weekly data:
dat_case_inc_weekly <- aggregate(dat_case_inc[, c("value")],
                                 by = list(week = dat_case_inc$week,
                                           year = dat_case_inc$year,
                                           location = dat_case_inc$location,
                                           location_name = dat_case_inc$location_name),
                                 FUN = sum)
colnames(dat_case_inc_weekly)[5] <- "inc_case"

# add target_end_date variable:
target_end_dates <- aggregate(dat_case_inc[, c("date")],
                              by = list(week = dat_case_inc$week,
                                        year = dat_case_inc$year,
                                        location = dat_case_inc$location,
                                        location_name = dat_case_inc$location_name),
                              FUN = max)
colnames(target_end_dates)[5] <- "target_end_date"

dat_case_inc_weekly <- merge(dat_case_inc_weekly, target_end_dates,
                             by = c("week", "year", "location", "location_name"))


# put everything together:
dat_weekly <- merge(dat_case_inc_weekly, dat_cum,
                    by.x = c("target_end_date", "location", "location_name"),
                    by.y = c("date", "location", "location_name"))
colnames(dat_weekly)[colnames(dat_weekly) == "value"] <- "cum_case"


# generate forecasts for Germany:

case_forecasts_de <- NULL

# run through locations in Germany:
locations_de <- unique(dat_weekly$location)
locations_de <- locations_de[grepl("GM", locations_de)]

for(loc in locations_de){
  cat("Starting", loc, "\n")
  
  # put everything together:
  forecasts_location <- baseline_forecast(dat_weekly = dat_weekly, loc = loc,
                                          target = "case", forecast_date = forecast_date)
  
  # and add to large table:
  if(is.null(case_forecasts_de)){
    case_forecasts_de <- forecasts_location
  }else{
    case_forecasts_de <- rbind(case_forecasts_de, forecasts_location)
  }
}

if(!(all(weekdays(case_forecasts_de$target_end_date) == "Saturday"))){
  warning("target_end_days are not all Saturdays!")
} else{
  # store:
  write.csv(case_forecasts_de, file = paste0(path_hub, "/data-processed/KIT-baseline/", forecast_date, "-Germany-KIT-baseline-case.csv"), row.names = FALSE)
}


# generate forecasts for Poland:

case_forecasts_pl <- NULL

# run through locations in Poland:
locations_poland <- unique(dat_weekly$location)
locations_poland <- locations_poland[grepl("PL", locations_poland)]

for(loc in locations_poland){
  cat("Starting", loc, "\n")
  
  # put everything together:
  forecasts_location <- baseline_forecast(dat_weekly = dat_weekly, loc = loc,
                                          target = "case", forecast_date = forecast_date)
  
  # and add to large table:
  if(is.null(case_forecasts_pl)){
    case_forecasts_pl <- forecasts_location
  }else{
    case_forecasts_pl <- rbind(case_forecasts_pl, forecasts_location)
  }
}

if(!(all(weekdays(case_forecasts_pl$target_end_date) == "Saturday"))){
  warning("target_end_days are not all Saturdays!")
} else{
  # store:
  write.csv(case_forecasts_pl, file = paste0(path_hub, "/data-processed/KIT-baseline/", forecast_date, "-Poland-KIT-baseline-case.csv"), row.names = FALSE)
}

