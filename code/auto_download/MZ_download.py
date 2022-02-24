# -*- coding: utf-8 -*-
"""
Created on Thu Jul 29 18:37:07 2021

@author: Jannik
"""

import urllib.request
import glob
from unidecode import unidecode
import os
import zipfile
import pandas as pd
import datetime
import shutil
import datetime
    
# look up abbreviations of voivodships

terit_to_abbr = {"t24": "PL83", "t14": "PL78", "t12": "PL77", "t30": "PL86", 
                 "t10": "PL74", "t02": "PL72", "t22": "PL82", "t18": "PL80",
                 "t04": "PL73", "t06": "PL75", "t16": "PL79", "t26": "PL84", 
                 "t20": "PL81", "t32": "PL87", "t28": "PL85", "t08": "PL76", 
                 "t00": "PL"}

# due to unknown encoding we have to map the names back to real names
map_abbr_name = {"PL72": "Dolnoslaskie", "PL73": "Kujawsko-Pomorskie",
                 "PL75": "Lubelskie", "PL76": "Lubuskie", "PL74": "Lodzkie",
                 "PL77": "Malopolskie", "PL78": "Mazowieckie",
                 "PL79": "Opolskie", "PL80": "Podkarpackie", "PL81": "Podlaskie",
                 "PL82": "Pomorskie", "PL83": "Slaskie", "PL84": "Swietokrzyskie",
                 "PL85": "Warminsko-Mazurskie", "PL86": "Wielkopolskie",
                 "PL87": "Zachodniopomorskie", "PL": "Poland"}

# download raw zip file
urllib.request.urlretrieve("https://arcgis.com/sharing/rest/content/items/a8c562ead9c54e13a135b02e0d875ffb/data", "poland.zip")

# extract file
with open(os.path.abspath("poland.zip"), mode="rb") as file:
    zip_ref = zipfile.ZipFile(file)
    os.mkdir(os.path.join(os.getcwd(), "poland_unzip"))
    zip_ref.extractall("poland_unzip")

curr_inc_case = pd.read_csv("../../data-truth/MZ/truth_MZ-Incident Cases_Poland.csv")
curr_inc_deaths = pd.read_csv("../../data-truth/MZ/truth_MZ-Incident Deaths_Poland.csv")

curr_cum_case = pd.read_csv("../../data-truth/MZ/truth_MZ-Cumulative Cases_Poland.csv")
curr_cum_deaths = pd.read_csv("../../data-truth/MZ/truth_MZ-Cumulative Deaths_Poland.csv")

inc_case_dfs = []
inc_death_dfs = []

# get csv files
for file in os.listdir("./poland_unzip"):
    if file.endswith(".csv"):
       
        date_raw = file[0:8]
        date = datetime.datetime.strptime(date_raw[0:4] + "." + date_raw[4:6] + "." + date_raw[6:], "%Y.%m.%d")
        
        if date > datetime.datetime.strptime("2021.07.15", "%Y.%m.%d"):
            
            print("Processing date: {}".format(date))
            
            df = pd.read_csv(os.path.join(os.path.join(os.getcwd(), "poland_unzip"), file), sep=";", encoding="cp1252")
            df.drop(columns=["wojewodztwo"], inplace=True)
                
            df["location"] = df["teryt"].apply(lambda x: terit_to_abbr[x])
            df["location_name"] = df["location"].apply(lambda x: map_abbr_name[x])
            
            #extract date from filename
            df["date"] = (date_raw[0:4] + "." + date_raw[4:6] + "." + date_raw[6:])
            df["date"] = pd.to_datetime(df["date"], format="%Y.%m.%d")
            #shift to ecdc
            df["date"] = df["date"].apply(lambda x: x + datetime.timedelta(days=1))
            
            if "liczba_wszystkich_zakazen" in df.columns:
                inc_case_df = df[["date", "location_name", "location", "liczba_wszystkich_zakazen"]].rename(columns={"liczba_wszystkich_zakazen": "value"})
            
            if "liczba_przypadkow" in df.columns:
                inc_case_df = df[["date", "location_name", "location", "liczba_przypadkow"]].rename(columns={"liczba_przypadkow": "value"})    
            
            inc_case_dfs.append(inc_case_df)
            
            inc_death_df = df[["date", "location_name", "location", "zgony"]].rename(columns={"zgony": "value"})
            inc_death_dfs.append(inc_death_df)

inc_case_df = pd.concat(inc_case_dfs)
inc_death_df = pd.concat(inc_death_dfs)

# only use new data
last_update = curr_inc_case["date"].max()

# cut off dates
inc_case_df = inc_case_df[inc_case_df["date"] > last_update]
inc_death_df = inc_death_df[inc_death_df["date"] > last_update]
inc_case_df["date"] = inc_case_df["date"].dt.date
inc_death_df["date"] = inc_death_df["date"].dt.date

# add new data to dataframe
final_inc_case = pd.concat([curr_inc_case, inc_case_df])
final_inc_case = final_inc_case.set_index("date")

final_inc_deaths = pd.concat([curr_inc_deaths, inc_death_df])
final_inc_deaths = final_inc_deaths.set_index("date")

#create latest cumulatve data
cum_case_df = inc_case_df.copy()
cum_case_df["value"] = cum_case_df.groupby("location").cumsum()

cum_death_df = inc_death_df.copy()
cum_death_df["value"] = cum_death_df.groupby("location").cumsum()

# add up cum data
latest_death_sum = curr_cum_deaths[curr_cum_deaths["date"] == curr_cum_deaths["date"].max()][["location", "value"]]
latest_death_sum = pd.Series(latest_death_sum.value.values, index=latest_death_sum.location).to_dict()

latest_case_sum = curr_cum_case[curr_cum_case["date"] == curr_cum_case["date"].max()][["location", "value"]]
latest_case_sum = pd.Series(latest_case_sum.value.values, index=latest_case_sum.location).to_dict()

def update_cumulative(location, value, previous_cumulative):
    return value + previous_cumulative[location]

cum_death_df["value"] = cum_death_df.apply(lambda row: update_cumulative(row["location"], row["value"], latest_death_sum), axis=1)
cum_case_df["value"] = cum_case_df.apply(lambda row: update_cumulative(row["location"], row["value"], latest_case_sum), axis=1)

final_cum_case = pd.concat([curr_cum_case, cum_case_df])
final_cum_case = final_cum_case.set_index("date")

final_cum_death = pd.concat([curr_cum_deaths, cum_death_df])
final_cum_death = final_cum_death.set_index("date")

# write to file
final_inc_case.to_csv("../../data-truth/MZ/truth_MZ-Incident Cases_Poland.csv")
final_cum_case.to_csv("../../data-truth/MZ/truth_MZ-Cumulative Cases_Poland.csv")
final_inc_deaths.to_csv("../../data-truth/MZ/truth_MZ-Incident Deaths_Poland.csv")
final_cum_death.to_csv("../../data-truth/MZ/truth_MZ-Cumulative Deaths_Poland.csv")

# clean up
shutil.rmtree("./poland_unzip")
os.remove("poland.zip")
