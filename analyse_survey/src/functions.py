import os
import pandas as pd
import numpy as np

from scipy import mean
from scipy.stats import sem, t
from scipy.stats import chi2_contingency


def remove_outliers(x):
    x.loc[~x.between(x.quantile(.01), x.quantile(.99))] = np.NaN
    return x


def get_movement(xclick, yclick):
    """Transforms coordinates into relative movement. It removes outliers"""
    dx_df = xclick.astype('float64').apply(remove_outliers).diff(axis=1)
    dy_df = yclick.astype('float64').apply(remove_outliers).diff(axis=1)

    d = dx_df.div(dy_df)
    return d.add_prefix('dclick_')


def get_seconds(t):
    return t.dt.total_seconds()


def calculate_times(time_df):
    delta_time_df = time_df.apply(pd.to_datetime, unit = 's')
    delta_time_df = delta_time_df.fillna(axis=1, method='ffill').diff(axis=1)
    delta_time_df = delta_time_df.replace(pd.Timedelta('0 days 00:00:00'), np.nan)
    delta_time_df = delta_time_df.apply(get_seconds, axis=1)

    delta_time_df['recorded'] = delta_time_df.count(axis=1) + 1
    delta_time_df['sum'] = delta_time_df.sum(axis=1, skipna=True)
    delta_time_df['median'] = delta_time_df.median(axis=1, skipna=True)
    delta_time_df['mean'] = delta_time_df.mean(axis=1, skipna=True)
    delta_time_df['std'] = delta_time_df.std(axis=1, skipna=True)

    print('Calculating click times...')
    return delta_time_df.add_prefix('time_')


def read_data(path='data'):
    quiz_path = 'QuizData.tsv'
    quiz = pd.read_table(path + os.sep + quiz_path)
    fields = np.delete(quiz.columns, 1)
    print('Loaded ' + quiz_path + ', with ' +
          str(quiz.UID.nunique()) + ' unique IDs and ' +
          str(quiz.PartnerUID.nunique()) + ' unique partner UIDs in ' + str(quiz.shape[0]) + ' rows')

    time_path = 'TimeData.tsv'
    time_df = pd.read_table(path + os.sep + time_path, usecols=fields)
    print('Loaded ' + time_path + ', with ' +
          str(time_df.UID.nunique()) + ' unique UIDs in ' + str(time_df.shape[0]) + ' rows')
    time_df.set_index('UID', inplace=True)
    time_df = time_df[~time_df.index.duplicated(keep='first')]

    user_path = 'UserBehaviourData.tsv'
    user = pd.read_table(path + os.sep + user_path)
    print('Loaded ' + user_path + ', with ' +
          str(user.PartnerUID.nunique()) + ' unique UIDs in ' + str(user.shape[0]) + ' rows')
    user.set_index('PartnerUID', inplace=True)

    x_path = 'XClickCoordinateData.tsv'
    xclick = pd.read_table(path + os.sep + x_path, usecols=fields)
    print('Loaded ' + x_path + ', with ' +
          str(xclick.UID.nunique()) + ' unique UIDs in ' + str(xclick.shape[0]) + ' rows')
    xclick.set_index('UID', inplace=True)
    xclick = xclick[~xclick.index.duplicated(keep='first')]

    y_path = 'YClickCoordinateData.tsv'
    yclick = pd.read_table(path + os.sep + y_path, usecols=fields)
    print('Loaded ' + y_path + ', with ' +
          str(yclick.UID.nunique()) + ' unique UIDs in ' + str(yclick.shape[0]) + ' rows')
    yclick.set_index('UID', inplace=True)
    yclick = yclick[~yclick.index.duplicated(keep='first')]

    return user, quiz, time_df, xclick, yclick


def calculate_confidence(x, confidence=0.95):
    x = x.dropna()
    n = len(x)
    m = mean(x)
    std_err = sem(x)
    h = std_err * t.ppf((1 + confidence) / 2, n - 1)
    start = max(0, round(m - h, 2))
    end = round(m + h, 2)
    print('C.I.: [ ' + str(start) + ', ' + str(end) + ' ]')


def cramer_v(x, y):
    """Cramer's V categorical correlation - https://en.wikipedia.org/wiki/Cram%C3%A9r%27s_V"""
    table = np.array(pd.crosstab(x, y, rownames=None, colnames=None))
    chisq = chi2_contingency(table)[0]
    n = np.sum(table)
    mindim = min(table.shape)-1
    return round(np.sqrt(chisq/(n * mindim))*100, 2)


def display_scores(scores):
    print("Scores: {0}\nMean: {1:.3f}\nStd: {2:.3f}".format(scores, np.mean(scores), np.std(scores)))


def report_best_scores(results, n_top=3):
    for i in range(1, n_top + 1):
        candidates = np.flatnonzero(results['rank_test_score'] == i)
        for candidate in candidates:
            print("Model with rank: {0}".format(i))
            print("Mean validation score: {0:.3f} (std: {1:.3f})".format(
                  results['mean_test_score'][candidate],
                  results['std_test_score'][candidate]))
            print("Parameters: {0}".format(results['params'][candidate]))
            print("")
