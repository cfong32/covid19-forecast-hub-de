import pandas as pd
import requests

todays_date = str(pd.to_datetime('today').date())

url = 'https://www.rki.de/DE/Content/InfAZ/N/Neuartiges_Coronavirus/Daten/VOC_VOI_Tabelle.xlsx?__blob=publicationFile'

# download Excel file
resp = requests.get(url)
with open("../../data-truth/RKI/variants/raw/{}_variants_raw.xls".format(todays_date), 'wb') as output:
    output.write(resp.content)

# load both sheets
xls = pd.ExcelFile("../../data-truth/RKI/variants/raw/{}_variants_raw.xls".format(todays_date))
df1 = pd.read_excel(xls, 'VOC')
df2 = pd.read_excel(xls, 'VOI')

# process variants of concern
df1 = df1.iloc[:-1, ]
df1.KW = df1.KW.str[2:].astype(int)
df1.columns = [c.strip(' \(\%\)').replace('Anzahl', 'count').replace('Anteil', 'proportion') if c != 'KW' else 'week' for c in df1.columns]
df1 = df1.round(1)

df1.to_csv('../../data-truth/RKI/variants/archive/{}_variants_of_concern_sample.csv'.format(todays_date), index=False)
df1.to_csv('../../data-truth/RKI/variants/variants_of_concern_sample.csv', index=False)


# process variants of interest
df2 = df2.iloc[:-1, ]
df2.KW = df2.KW.str[2:].astype(int)
df2.columns = [c.strip(' \(\%\)').replace('Anzahl', 'count').replace('Anteil', 'proportion') if c != 'KW' else 'week' for c in df2.columns]
df2 = df2.round(1)

df2.to_csv('../../data-truth/RKI/variants/archive/{}_variants_of_interest_sample.csv'.format(todays_date), index=False)
df2.to_csv('../../data-truth/RKI/variants/variants_of_interest_sample.csv', index=False)
