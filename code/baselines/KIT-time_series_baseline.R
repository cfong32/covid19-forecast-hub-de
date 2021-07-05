# Using forecast::ets to generate a non-naive time series model baseline forecast.

library(forecast)

# setwd("/home/johannes/Documents/Projects/KIT-baseline")
source("functions_kit-baseline.R") # read in helper functions
source("functions_kit-time_series_baseline.R") # read in helper functions
Sys.setlocale("LC_ALL", "en_US.utf8") # Linux
# Sys.setlocale("LC_ALL","English") # Windows

# select forecast_date for which to generate forecasts
forecast_date <- (Sys.Date() - 0:6)[weekdays(Sys.Date() - 0:6) == "Monday"] # latest Monday
last_obs_week <- MMWRweek::MMWRweek(forecast_date)$MMWRweek - 1

# path where the covid19-forecast-hub-de repository is stored
path_hub <- "../.."
source(paste0(path_hub, "/code/R/auxiliary_functions.R"))

# read in incident and cumulative death data:
dat_truth <- read.csv(paste0(path_hub, "/app_forecasts_de/data/",  "truth_to_plot_ecdc.csv"),
                      colClasses = list(date = "Date"), stringsAsFactors = FALSE)

# check that truth data are up to date:
if(max(dat_truth$date) < forecast_date - 2) warning("Please update the covid19-forecast-hub-de repository.")


# extract locations:
locations_gm <- read.csv(paste0(path_hub, "/template/state_codes_germany.csv"), stringsAsFactors = FALSE)
locations_pl <- read.csv(paste0(path_hub, "/template/state_codes_poland.csv"), stringsAsFactors = FALSE)
locations_pl$state_name <- unaccent(locations_pl$state_name) # remove special characters.

# run for Germany, cases:
cases_gm <- NULL
for(i in 1:nrow(locations_gm)){
  cat("Starting", locations_gm$state_name[i], "...\n")
  to_add <- forecast_esm(dat = dat_truth,
                         forecast_date = forecast_date,
                         location = locations_gm$state_code[i],
                         location_name = locations_gm$state_name[i],
                         target_type = "case",
                         n_training = 12, n_sim = 10000)

  if(is.null(cases_gm)){
    cases_gm <- to_add
  }else{
    cases_gm <- rbind(cases_gm, to_add)
  }
}
write.csv(cases_gm, file = paste0(path_hub, "/data-processed/KIT-time_series_baseline/",
                                  forecast_date, "-Germany-KIT-time_series_baseline-case.csv"),
          row.names = FALSE)


# run for Poland, cases:
cases_pl <- NULL
for(i in 1:nrow(locations_pl)){
  cat("Starting", locations_pl$state_name[i], "...\n")
  to_add <- forecast_esm(dat = dat_truth,
                         forecast_date = forecast_date,
                         location = locations_pl$state_code[i],
                         location_name = locations_pl$state_name[i],
                         target_type = "case",
                         n_training = 12, n_sim = 10000)

  if(is.null(cases_pl)){
    cases_pl <- to_add
  }else{
    cases_pl <- rbind(cases_pl, to_add)
  }
}
write.csv(cases_pl, file = paste0(path_hub, "/data-processed/KIT-time_series_baseline/",
                                  forecast_date, "-Poland-KIT-time_series_baseline-case.csv"),
          row.names = FALSE)


# run for Germany, deaths:
deaths_gm <- NULL
for(i in 1:nrow(locations_gm)){
  cat("Starting", locations_gm$state_name[i], "...\n")
  to_add <- forecast_esm(dat = dat_truth,
                         forecast_date = forecast_date,
                         location = locations_gm$state_code[i],
                         location_name = locations_gm$state_name[i],
                         target_type = "death",
                         n_training = 12, n_sim = 10000)

  if(is.null(deaths_gm)){
    deaths_gm <- to_add
  }else{
    deaths_gm <- rbind(deaths_gm, to_add)
  }
}
write.csv(deaths_gm, file = paste0(path_hub, "/data-processed/KIT-time_series_baseline/",
                                   forecast_date, "-Germany-KIT-time_series_baseline.csv"),
          row.names = FALSE)

# run for Poland, deaths:
deaths_pl <- NULL
for(i in 1:nrow(locations_pl)){
  cat("Starting", locations_pl$state_name[i], "...\n")
  to_add <- forecast_esm(dat = dat_truth,
                         forecast_date = forecast_date,
                         location = locations_pl$state_code[i],
                         location_name = locations_pl$state_name[i],
                         target_type = "death",
                         n_training = 12, n_sim = 10000)

  if(is.null(deaths_pl)){
    deaths_pl <- to_add
  }else{
    deaths_pl <- rbind(deaths_pl, to_add)
  }
}
write.csv(deaths_pl, file = paste0(path_hub, "/data-processed/KIT-time_series_baseline/",
                                    forecast_date, "-Poland-KIT-time_series_baseline.csv"),
          row.names = FALSE)

