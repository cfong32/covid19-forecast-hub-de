import os
import pandas as pd
import numpy as np

df = pd.read_csv('../data/forecasts_to_plot.csv', parse_dates=['timezero'])

# load ecdc and jhu truth
ecdc = pd.read_csv('../data/truth_to_plot_ecdc.csv', parse_dates=['date'])
jhu = pd.read_csv('../data/truth_to_plot_jhu.csv', parse_dates=['date'])

# transform to long format
ecdc = pd.melt(ecdc, id_vars=ecdc.columns[:-4], value_vars=['cum_death', 'inc_death', 'cum_case', 'inc_case'], 
               var_name='merge_target', value_name='truth')[['date', 'location', 'merge_target', 'truth']]
ecdc['truth_data_source'] = 'ECDC'

jhu = pd.melt(jhu, id_vars=jhu.columns[:-4], value_vars=['cum_death', 'inc_death', 'cum_case', 'inc_case'], 
               var_name='merge_target', value_name='truth')[['date', 'location', 'merge_target', 'truth']]
jhu['truth_data_source'] = 'JHU'

# store in one dataframe
truth = pd.concat([ecdc, jhu])


# merge forecasts_to_plot and truth
df['saturday0'] = df.timezero - pd.to_timedelta('2 days')
df['merge_target'] = df.target.str[11:].replace(' ', '_', regex=True).str.strip('_')

df = df.merge(truth, left_on=['truth_data_source', 'location', 'saturday0', 'merge_target'], 
              right_on=['truth_data_source', 'location', 'date', 'merge_target'], how='left')

# find 'forecast groups' without 0 wk ahead
temp = df.groupby(['model', 'location', 'saturday0', 'merge_target']).filter(lambda x: ~x.target.str.startswith('0 wk').any())

# reuse first entry in each 'forecast group'
temp = temp.groupby(['model', 'location', 'saturday0', 'merge_target']).first().reset_index()

# adjust relevant cells
temp.type = 'observed'
temp.loc[:, 'quantile'] = np.nan
temp.target = '0 wk ahead ' + temp.merge_target.replace('_', ' ', regex=True)
temp.value = temp.truth
temp.target_end_date = temp.saturday0

# concat old forecasts_to_plot and newly added last observed values (0 wk ahead)
df = pd.concat([df, temp])

# sort models and adjust format
models = df.model.unique().tolist()
models.sort(key=str.casefold)

ensembles = ['KITCOVIDhub-mean_ensemble', 'KITCOVIDhub-median_ensemble', 'KITCOVIDhub-inverse_wis_ensemble']
baselines = [m for m in models if 'baseline' in m]
individual_models = [m for m in models if m not in ensembles + baselines ]

models = ensembles + individual_models +  baselines

df.model = pd.Categorical(df.model, models, ordered=True)
df = df.sort_values(['model', 'forecast_date', 'target_end_date', 'location', 'target', 'type', 'quantile']).reset_index(drop=True)

df = df[['forecast_date', 'target', 'target_end_date', 'location', 'type',
       'quantile', 'value', 'timezero', 'model', 'truth_data_source',
       'shift_ECDC', 'shift_JHU', 'first_commit_date']]

# export csv - light version to load faster
df_light = df[(df.timezero.isin(pd.Series(df.timezero.unique()).nlargest(8)) & df.location.isin(['GM', 'PL'])) | 
        (df.timezero.isin(pd.Series(df.timezero.unique()).nlargest(2)) & (~df.location.isin(['GM', 'PL'])))]

df_light.to_csv('../data/forecasts_to_plot.csv', index=False)

# export csv for archive - limited to 100 MB
def export_limited_csv(df, path = '../data/forecasts_to_plot_archive.csv', 
                     remove_models = ['KIT-extrapolation_baseline', 'KIT-time_series_baseline'], 
                     max_size = 100):
    df.to_csv(path, index=False)
    file_size = os.path.getsize(path)/(1024*1024)
    print('Current file size: ', file_size)
    
    # remove selected models
    if file_size > max_size:
        if len(remove_models) != 0:        
            df = df[~df.model.isin(remove_models)]
            df.to_csv(path, index=False)
            file_size = os.path.getsize(path)/(1024*1024)
            print('The following models have been removed: ', remove_models)
            print('New file size: ', file_size)
    
    # first step: remove rows from beginning to reduce file to approx. 100 MB with rough guess
    if file_size > max_size:
        dates = df.timezero.sort_values().unique()
        nrows_to_cut = (1 - max_size/file_size)*len(df) # estimated number of rows to cut
        old_rows = 0
        for d in dates: # we remove dates from the beginning until we exceed nrows_to_cut
            if old_rows < nrows_to_cut:
                old_rows += len(df[df.timezero == d])
                if old_rows >= nrows_to_cut:
                    cut_date = d
                    break
        df = df[(df.timezero > cut_date) | df.location.isin(['GM', 'PL'])]
        df.to_csv(path, index=False)
        file_size = os.path.getsize(path)/(1024*1024)
        print('Excluded subnational forecasts up to: ', cut_date)
        print('New file size: ', file_size)
    
    # second step: remove one date after the other (subnational only) to reduce below 100 MB
    while file_size > max_size:
        min_date = df[~df.location.isin(['GM', 'PL'])].timezero.unique().min()
        df = df[(df.timezero != min_date) | df.location.isin(['GM', 'PL'])]
        df.to_csv(path, index=False)
        file_size = os.path.getsize(path)/(1024*1024)
        print('Subnational forecast removed for: ', min_date)
        print('New file size: ', file_size)
    
    print('Done. Current file size ({} MB) is below limit.'.format(file_size))

export_limited_csv(df, path = '../data/forecasts_to_plot_archive.csv', 
                 remove_models = ['KIT-extrapolation_baseline', 'KIT-time_series_baseline'], 
                 max_size = 100)
