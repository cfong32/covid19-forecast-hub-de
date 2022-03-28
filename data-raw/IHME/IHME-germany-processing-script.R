# Author: Konstantin Görgen
# Date: Mon May 11 13:57:10 2020
# --------------
# Modification: Added Submission and Forecast date
# Author: Konstantin Görgen
# Date: 18.05.2020
# --------------
#################################################################################
###### This file has been adapted from code provided in the US COVID19 forecast hub:
###### https://github.com/reichlab/covid19-forecast-hub/tree/master/data-raw/IHME/IHME-processing.R
###### The original file has been provided under the MIT license, and so is this adapted version.
#################################################################################

## reformat IHME forecasts
# Run from data-raw/IHME
source("process_IHME-germany_functions.R")
require(tidyverse)
require(MMWRweek)
require(lubridate)


#Run all files for the second period (to update incident deaths)
run_second_period<-TRUE
#define second period dates:
mondays_second_period<-seq(as.Date("2021-01-11"),as.Date("2021-03-29"),length.out=12)

path_export<-ifelse(run_second_period,
                    "../../data-temp/IHME-CurveFit/Second_period_incident_deaths/",
                    "../../data-processed/IHME-CurveFit/")
## list all files and read
filepaths <- list.files("./",
                        pattern = "Hospitalization_all_locs.csv",
                        recursive = TRUE,
                        full.names = FALSE,
                        ignore.case = TRUE)

#remove files that are not main model
filepaths<-filepaths[-c(grep("Best",filepaths),grep("Worse",filepaths),
                        grep("best",filepaths),grep("worse",filepaths),
                        grep("vaccine",filepaths))]

# only process files that have not been created yet
filenames_processed <- list.files("../../data-processed/IHME-CurveFit/", pattern=".csv", full.names=FALSE)
dates_processed <- unlist(lapply(filenames_processed, FUN = function(x) substr(basename(x), 0, 10)))


for(country in c("Germany","Poland"))
{
  # print(country)
  #check for IHME first forecast date
  list_forecast<-list()
  for (i in 1:length(filepaths))
  {
    list_forecast[[i]]<-get_forecast_date(filepaths[i],country=country)
  }
  real_vs_reported<-t(as.data.frame(list_forecast))
  
  rownames(real_vs_reported)<-as.character(real_vs_reported[,1])
  
  #delete reports that have no new forecast horizon, always keep oldest
  keep_report<-rep(TRUE,length(filepaths))
  for (i in 2:dim(real_vs_reported)[1]){
    keep_report[i]<-!real_vs_reported[i,2]==real_vs_reported[i-1,2]
  }
  
  # exclude forecasts already processed
  # exclude everything with date before July
  
  #or if running for incident death inclusion, only include second evaluation period
  
  keep_date<-rep(TRUE,length(filepaths))
  if(run_second_period)
  {
    for (i in 1:dim(real_vs_reported)[1]){
      keep_date[i] <- !(real_vs_reported[i,1] <= as.Date("2020-12-22") | real_vs_reported[i,1] >= as.Date("2021-03-26"))
    }
  }else {
    for (i in 1:dim(real_vs_reported)[1]){
      keep_date[i] <- !(real_vs_reported[i,1] %in% dates_processed | real_vs_reported[i,1] <= as.Date("2020-07-01"))
    }
  }
  
  
  # filepaths<-filepaths[real_vs_reported[keep_report,2]>as.Date("2020-07-01")]
  # forecast_dates<-real_vs_reported[keep_report & real_vs_reported[,2]>as.Date("2020-07-01"),]
  
  filepaths_to_process <- filepaths[keep_report & keep_date]
  # forecast_dates <- real_vs_reported[keep_report & keep_date,]
  forecast_dates <- real_vs_reported[keep_report & keep_date,1]
  
  print(paste0("Generating ", country, " forecasts for the following dates:", forecast_dates))
  # stop()
  
  for (i in 1:length(filepaths_to_process)) {
    #changed submission date to real forecast date, to change back, change to [i,1] in submission_date=forecast_dates[i,2]
    #Update 10.08: Set forecast date to submission date for consistency reasons, i.e. forecast_date=forecast_dates[i,1] instead of [i,2]
    # Sometimes, values that are actually forecasts will be labeled as observations now
    # Idea is the assumptions that submission should be on same day as forecast generation 
    
    # formatted_file <- make_qntl_dat(path=filepaths_to_process[i],forecast_date=forecast_dates[i,1],
    #                                 submission_date=forecast_dates[i,1],country=country) 
    
    date_print <- get_date(filepaths_to_process[i])
    if(run_second_period)
    {
      date_fc<-get_date(filepaths_to_process[i])
      #use the closest monday in that follows a given date (or is exactly on that monday) and get index
      min_positive_diff<-min((mondays_second_period-date_fc)[mondays_second_period-date_fc>=0])
      date_print<-mondays_second_period[which(mondays_second_period-date_fc==min_positive_diff)]
    }
    
    formatted_file <- make_qntl_dat(path=filepaths_to_process[i],forecast_date=forecast_dates[i],
                                    submission_date=forecast_dates[i],country=country,
                                    run_second_period=run_second_period,
                                    second_period_target_monday=date_print)
    
    #date<-forecast_dates[i,2]
    
    write_csv(
      formatted_file,
      path = paste0(path_export,
                    date_print,
        "-",country,"-IHME-CurveFit.csv"
      )
    )
    print(paste0("Finished with date ",date_print," in country ", country) )
  }
}
#Warning: "NAs introduced by coercion" is fine and issued when NA is written in column quantile for observed values

