import pandas as pd

df = pd.read_csv('https://raw.githubusercontent.com/ard-data/2020-rki-impf-archive/master/data/9_csv_v2/all.csv')
df.to_csv('../../data-truth/RKI/vaccination_Germany.csv', index=False)
