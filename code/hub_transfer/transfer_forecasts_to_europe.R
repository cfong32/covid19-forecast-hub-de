# paths to the two hubs:
path_hub_de_pl <- "./covid19-forecast-hub-de"
path_hub_eu <- "./test"

# the forecast_dates for which to transfer forecasts
forecast_dates <- as.character(Sys.Date() - 0:3) # as.character(as.Date("2021-04-05") - 0:3)
# forecast_dates <- as.character(as.Date("2021-04-05") - 0:2)
# vector of all models submitted to DE/PL
# models_de_pl <- c("MOCOS-agent1", "FIAS_FZJ-Epi1Ger", "ICM-agentModel", "ITWW-county_repro", 
#            "Karlen-pypm", "LeipzigIMISE-SECIR", "MIT_CovidAnalytics-DELPHI", # "MIMUW-StochSEIR",
#            "MOCOS-agent1", "itwm-dSEIR")
models_de_pl <- list.dirs(paste0(path_hub_de_pl, "/data-processed"), full.names = FALSE)
# some manual exclusion:
models_de_pl <- models_de_pl[!grepl("KIT", models_de_pl) & 
                               models_de_pl != "" &
                               models_de_pl != "USC-SIkJalpha" &
                               models_de_pl != "MIMUW-StochSEIR" &
                               models_de_pl != "LeipzigIMISE-SECIR"] # exclude models containing "KIT"

# loop over teams and forecast_dates
for(team in models_de_pl){
  cat("--------------\n", team, "\n")
  
  for(forecast_date in forecast_dates){
    
    # determine file name for EU Hub
    file_eu <- paste0(path_hub_eu, "/data-processed/", team, "/", forecast_date, "-", team, ".csv")
    
    # check if this file already exists
    if(file.exists(file_eu)){
      cat("File", file_eu, "already exists in covid19-forecast-hub-europe.")
    }else{ # if not: process
      dat_case_de <- dat_death_de <- dat_death_pl <- dat_case_pl <- NULL
      
      file_death_de <- paste0(path_hub_de_pl, "/data-processed/", team, "/", forecast_date, "-Germany-", team, ".csv")
      print(file_death_de)
      if(file.exists(file_death_de)){
        dat_death_de <- read.csv(file_death_de)
        cat(paste0("Found file ", basename(file_death_de)), "\n")
        dat_death_de$location_name <- NULL
      }
      
      file_case_de <- paste0(path_hub_de_pl, "/data-processed/", team, "/", forecast_date, "-Germany-", team, "-case.csv")
      if(file.exists(file_case_de)){
        dat_case_de <- read.csv(file_case_de)
        cat(paste0("Found file ", basename(file_case_de)), "\n")
        dat_case_de$location_name <- NULL
      }
      
      file_death_pl <- paste0(path_hub_de_pl, "/data-processed/", team, "/", forecast_date, "-Poland-", team, ".csv")
      if(file.exists(file_death_pl)){
        dat_death_pl <- read.csv(file_death_pl)
        cat(paste0("Found file ", basename(file_death_pl)), "\n")
        dat_death_pl$location_name <- NULL
      }
      
      file_case_pl <- paste0(path_hub_de_pl, "/data-processed/", team, "/", forecast_date, "-Poland-", team, "-case.csv")
      if(file.exists(file_case_pl)){
        dat_case_pl <- read.csv(file_case_pl)
        cat(paste0("Found file ", basename(file_case_pl)), "\n")
        dat_case_pl$location_name <- NULL
      }
      
      dat <- rbind(dat_case_de, dat_death_de, dat_case_pl, dat_death_pl)

      if(!is.null(dat)){
        # restrict to national level:
        dat <- subset(dat, location %in% c("GM", "PL"))
        
        # restrict to inc and week ahead:
        dat <- subset(dat, grepl("wk ahead inc", target))
        if(nrow(dat) > 0){ # handle case where no national level forecasts available
          cat("Preparing to write out ", paste0(forecast_date, "-", team), "\n")
          
          # re-factor location codes
          dat$location[dat$location == "GM"] <- "DE"
          
          # add scenario_id column:
          dat$scenario_id <- "forecast"
          
          # remove type == "observed"
          dat <- subset(dat, type %in% c("point", "quantile"))
          
          if(!dir.exists(paste0(path_hub_eu, "/data-processed/", team))){
            cat("Creating directory.\n")
            dir.create(paste0(path_hub_eu, "/data-processed/", team))
          }
          
          cat("Writing out.\n")
          write.csv(dat, file_eu, row.names = FALSE)
    
        }
      }
    }
  }
}

