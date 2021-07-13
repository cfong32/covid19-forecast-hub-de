# -*- coding: utf-8 -*-
"""
Created on Mon May 10 14:10:33 2021

@author: Jannik
"""

import requests
import pandas as pd
from datetime import datetime, date, timedelta
from pathlib import Path

# list all forecast files already present in the eu hub
url = "https://api.github.com/repos/epiforecasts/covid19-forecast-hub-europe/git/trees/main?recursive=1"
r = requests.get(url)
res = r.json()
files = [file["path"] for file in res["tree"] if (file["path"].startswith("data-processed/") and file["path"].endswith(".csv"))]

for file in files:
    date_str = file.split("/")[-1][:10]
    datetime_object = datetime.strptime(date_str, '%Y-%m-%d')
    
    # read in forecasts files of current week
    if date.today() - timedelta(days=8) < datetime_object.date():
        df = pd.read_csv("https://raw.githubusercontent.com/epiforecasts/covid19-forecast-hub-europe/main/" + file)
        
        #create directory
        Path("./euhub/" + "/".join(file.split("/")[:-1])).mkdir(parents=True, exist_ok=True)
        df.to_csv("./euhub/" + file, index=False)
        
                                        
