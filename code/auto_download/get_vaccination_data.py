import pandas as pd

df = pd.read_csv('https://raw.githubusercontent.com/ard-data/2020-rki-impf-archive/master/data/9_csv_v3/all.csv')

# rename columns
column_dict = {'region': 'location'}
df.rename(columns=column_dict, inplace=True)

# add location codes and names
locs = pd.read_csv('../../template/state_codes_germany.csv')

location_dict = dict(zip(df.location.unique(), ['Baden-Wurttemberg', 'Bavaria', 'Berlin', 'Brandenburg', 'Bremen', 'Hamburg',
                                              'Hesse', 'Mecklenburg-Vorpommern', 'Lower Saxony', 'North Rhine-Westphalia',
                                              'Rhineland-Palatinate', 'Saarland', 'Saxony', 'Saxony-Anhalt', 
                                              'Schleswig-Holstein', 'Thuringia', 'Germany']))

fips_dict = dict(zip(locs.state_name, locs.state_code))

df['location_name'] = df.location.replace(location_dict)
df['location'] = df.location_name.replace(fips_dict)

# translate metrics
def translate_metric(m):
    replacements = {'kumulativ': 'cumulative',
                    'erst': 'first',
                    'zweit': 'second',
                    'voll': 'full',
                    'dosen': 'doses',
                    'impfstelle': 'at',
                    'indikation': 'reason',
                    'differenz_zum_vortag': 'difference_to_previous',
                    'zentral': 'central',
                    'inzidenz': 'incidence',
                    'aerzte': 'gp',
                    'pflegeheim': 'nursingHome',
                    'quote': 'percentage',
                    'impf_' : 'vacc_', 
                    'alter': 'age', 
                    'unter': 'under',
                    'beruf': 'job',
                    'medizinisch': 'medical',
                    'personen': 'persons'
                   }
    for key, value in replacements.items():
        m = m.replace(key, value)
    return m

df.metric = df.metric.apply(translate_metric)

# reorder columns
df = df[['date', 'publication_date', 'location', 'location_name', 'metric', 'value']]

# filter
to_exclude = ['reason', 'biontech', 'moderna', 'astrazeneca', 'janssen']
df = df[~df.metric.str.contains('|'.join(to_exclude))]

df.to_csv('../../data-truth/RKI/vaccination/vaccination_Germany.csv', index=False)
