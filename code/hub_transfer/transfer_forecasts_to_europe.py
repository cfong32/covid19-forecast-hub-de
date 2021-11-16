# -*- coding: utf-8 -*-
"""
Created on Tue Apr 20 09:38:28 2021

@author: Jannik
"""

from datetime import datetime, timedelta
import os
import requests
import pandas as pd
from pathlib import Path

workdir = os.getcwd()
path_hub_de_pl = "../../"
path_hub_eu = "../../upload_eu"

# list all forecast file already present in the eu hub
url = "https://api.github.com/repos/epiforecasts/covid19-forecast-hub-europe/git/trees/main?recursive=1"
r = requests.get(url)
res = r.json()
files = [file["path"] for file in res["tree"] if (file["path"].startswith("data-processed/") and file["path"].endswith(".csv"))]

# list files pres
excluded_models = ["USC-SIkJalpha", "MIMUW-StochSEIR", "LeipzigIMISE-SECIR", "epiforecasts-EpiExpert", "epiforecasts-EpiNow2",
                   "epiforecasts-EpiNow2_secondary", "epiforecasts-EpiExpert_Rt", "epiforecasts-EpiExpert_direct", "HKUST-DNN_DA"]

# the forecast_dates for which to transfer forecasts
forecast_dates = [datetime.now() - timedelta(x) for x in range(4)]

models_de_pl = os.listdir(path_hub_de_pl + "/data-processed")
# some manual exclusion:
models_de_pl = [x for x in models_de_pl if "KIT" not in x and x not in excluded_models]

test =  []

for team in models_de_pl:
    
    print("------------" + "\n" + team)
    
    for date in forecast_dates:
        
        # check if this file already exists
        file_eu = "data-processed/" + team + "/" + datetime.strftime(date, '%Y-%m-%d') + "-" + team + ".csv"
        if file_eu in files:
            print("File {} already present in EU Hub".format(file_eu))
            
        else: #process
            dat_case_de = dat_death_de = dat_death_pl = dat_case_pl = None
            
            file_death_de = path_hub_de_pl + "data-processed/" + team + "/" + datetime.strftime(date, '%Y-%m-%d') + "-Germany-" + team + ".csv"
            if os.path.isfile(Path(file_death_de)):
                dat_death_de = pd.read_csv(file_death_de)
                print("Found file {}".format(file_death_de))
                try:
                    dat_death_de.drop(columns=["location_name"], inplace=True)
                # some files do not contain location name column
                except KeyError:
                    pass
            
            file_case_de = path_hub_de_pl + "data-processed/" + team + "/" + datetime.strftime(date, '%Y-%m-%d') + "-Germany-" + team + "-case.csv"
            if os.path.isfile(Path(file_case_de)):
                dat_case_de = pd.read_csv(file_case_de)
                print("Found file {}".format(file_case_de))
                try:
                    dat_case_de.drop(columns=["location_name"], inplace=True)
                # some files do not contain location name column
                except KeyError:
                    pass
            
            file_death_pl = path_hub_de_pl + "data-processed/" + team + "/" + datetime.strftime(date, '%Y-%m-%d') + "-Poland-" + team + ".csv"
            if os.path.isfile(Path(file_death_pl)):
                dat_death_pl = pd.read_csv(file_death_pl)
                print("Found file {}".format(file_death_pl))
                try:
                    dat_death_pl.drop(columns=["location_name"], inplace=True)
                # some files do not contain location name column
                except KeyError:
                    pass
            
            file_case_pl = path_hub_de_pl + "data-processed/" + team + "/" + datetime.strftime(date, '%Y-%m-%d') + "-Poland-" + team + "-case.csv"
            if os.path.isfile(Path(file_case_pl)):
                dat_case_pl = pd.read_csv(file_case_pl)
                print("Found file {}".format(file_case_pl))
                try:
                    dat_case_pl.drop(columns=["location_name"], inplace=True)
                # some files do not contain location name column
                except KeyError:
                    pass
            try:
                dat = pd.concat([dat_case_de, dat_death_de, dat_case_pl, dat_death_pl])
            except ValueError:
                dat = None
            
            # adapt format
            if dat is not None:
                dat = dat[dat["location"].isin(["GM", "PL"])]
                
                # restrict to inc and week ahead:
                dat = dat[dat["target"].str.contains("wk ahead inc")]
                
                if len(dat) > 0:
                    print("Preparing to write out "  + datetime.strftime(date, '%Y-%m-%d') + "-" + team)
                    
                    # re-factor location codes
                    dat["location"] = dat["location"].replace("GM", "DE")
                    
                    # add scenario_id column:
                    dat["scenario_id"] = "forecast"
                    
                    # remove type == "observed"
                    dat = dat[dat["type"].isin(["point", "quantile"])]
                    
                    if not os.path.exists(Path(path_hub_eu+ "/data-processed/"+ team)):
                        os.makedirs(Path(path_hub_eu+ "/data-processed/"+ team))
                    
                    dat["value"] = dat["value"].round(0).astype(int)
                    
                    dat.to_csv(Path(path_hub_eu + "/" + file_eu), index=False)
