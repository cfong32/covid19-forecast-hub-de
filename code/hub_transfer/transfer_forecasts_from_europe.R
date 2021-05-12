# paths to the two hubs:
path_hub_de_pl <- "../../"
path_hub_eu <- "../../euhub"

# vector of all models submitted to EU Hub:
models_eu <- list.dirs(paste0(path_hub_eu, "/data-processed"), full.names = FALSE)
# the forecast_dates for which to transfer forecasts
forecast_dates <- as.character(Sys.Date() - 0:3) # as.character(as.Date("2021-04-05") - 0:3)

# loop over models
for(team in models_eu){
  cat("\n---- ", team, " ----\n")
  for (forecast_date in forecast_dates) { # and over dates
    # file name (file may not exist)
    file_eu <- paste0(path_hub_eu, "/data-processed/", team, "/",
                      forecast_date, "-", team, ".csv")
    # check if file exists
    if(file.exists(file_eu)){
      cat("Found", basename(file_eu), "\n")
      # path where files need to be stored for DE/PL Hub
      path_team_de_pl <- paste0(path_hub_de_pl, "/data-processed/", team)
      if(!any(grepl(forecast_date, list.files(path_team_de_pl)))){
        # read data
        dat <- read.csv(file_eu)
        # remove scenario column
        dat$scenario_id <- NULL
        
        # extract Germany, cases:
        dat_GM_case <- subset(dat, location == "DE" & grepl("case", target))
        if(nrow(dat_GM_case) > 0){
          dat_GM_case$location <- "GM" # need to adapt location code
          dir.create(path_team_de_pl, showWarnings = FALSE) # create directory if necessary
          # write out:
          cat("Writing out cases, Germany. \n")
          write.csv(dat_GM_case, paste0(path_team_de_pl, "/", forecast_date, "-Germany-", team, "-case.csv"), row.names = FALSE)
        }
        
        
        # extract Germany, deaths:
        dat_GM_death <- subset(dat, location == "DE" & grepl("death", target))
        if(nrow(dat_GM_death) > 0){
          dat_GM_death$location <- "GM" # need to adapt location code
          dir.create(path_team_de_pl, showWarnings = FALSE) # create directory if necessary
          # write out:
          cat("Writing out deaths, Germany. \n")
          write.csv(dat_GM_death, paste0(path_team_de_pl, "/", forecast_date, "-Germany-", team, ".csv"), row.names = FALSE)
        }
        
        # extract Poland, cases:
        dat_PL_case <- subset(dat, location == "PL" & grepl("case", target))
        if(nrow(dat_PL_case) > 0){
          dat_PL_case$location <- "PL"
          dir.create(path_team_de_pl, showWarnings = FALSE) # create directory if necessary
          # write out:
          cat("Writing out cases, Poland. \n")
          write.csv(dat_PL_case, paste0(path_team_de_pl, "/", forecast_date, "-Poland-", team, "-case.csv"), row.names = FALSE)
        }
        
        # extract Poland, deaths:
        dat_PL_death <- subset(dat, location == "PL" & grepl("death", target))
        if(nrow(dat_PL_death) > 0){
          dat_PL_death$location <- "PL"
          dir.create(path_team_de_pl, showWarnings = FALSE) # create directory if necessary
          # write out:
          cat("Writing out deaths, Poland. \n")
          write.csv(dat_PL_death, paste0(path_team_de_pl, "/", forecast_date, "-Poland-", team, ".csv"), row.names = FALSE)
        }
      }else{
        "Already files present, skipping. \n"
      }
    }
  }
}

unlink(path_hub_eu, recursive=TRUE)
