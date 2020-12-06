import pickle
import numpy as np
import pandas as pd
import xgboost as xgb
import matplotlib.pyplot as plt

from src.functions import read_data, remove_outliers, \
    calculate_times, calculate_confidence, get_movement, report_best_scores
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.model_selection import RandomizedSearchCV, train_test_split
from sklearn.utils import compute_class_weight
from sklearn.dummy import DummyClassifier


# Load all data files
user, quiz, time_df, xclick, yclick = read_data()
questions = time_df.columns.values

##################################################
# Calculate response times per question
# (notice Q1 time can't be calculated, as we don't
# have timestamp for beginning of the test)
delta_time_df = calculate_times(time_df)
# Calculate the descriptive stats for response times
delta_time_df = delta_time_df.apply(remove_outliers)
delta_time_eda = delta_time_df.describe()

dt_bp_fig = plt.figure()
delta_time_bp = delta_time_df['time_' + questions].boxplot(fontsize='small')
dt_bp_fig.savefig('assets/boxplot.png')

shortest_q = delta_time_df['time_' + questions].mean().idxmin()
print('Shortest question: ' + shortest_q)
calculate_confidence(delta_time_df[shortest_q])

longest_q = delta_time_df['time_' + questions].mean().idxmax()
print('Longest question: ' + longest_q)
calculate_confidence(delta_time_df[longest_q])

# Median
questions[np.argsort(delta_time_df['time_' + questions].mean())[len(delta_time_df['time_' + questions].mean())//2]]


###########################################################
# Is there a relationship between Q1/Q2 and user behaviour?
# Which one is better predictor?

quiz.set_index('PartnerUID', inplace=True)
quiz = quiz.join(user, how='left')
quiz.set_index('UID', inplace=True)

quiz.pivot_table(index='Q1', columns='Flag', aggfunc='size', fill_value=0)
quiz.pivot_table(index='Q2', columns='Flag', aggfunc='size', fill_value=0)

quiz.Flag.value_counts()

cramer = quiz.corrwith(quiz.Flag, axis=0, method=cramer_v)

print('Correlation between Q1 and User Behaviour is: ' + str(cramer[0]) + '%')
print('Correlation between Q2 and User Behaviour is: ' + str(cramer[1]) + '%')

cramer.to_csv('data/cramer.csv')

###########################################################
# Build a model to predict user behaviour

# Set features as: answers + times + movement
quiz_encoded = pd.get_dummies(quiz.iloc[:, 0:59], prefix=questions, columns=questions)

quiz_encoded = quiz_encoded.join(quiz.Flag)

quiz_encoded = quiz_encoded.join(delta_time_df, how='left')

dclick = get_movement(xclick, yclick)
quiz_encoded = quiz_encoded.join(dclick, how='left')

# Clean NaN values
quiz_encoded.dropna(subset=['Flag', 'time_recorded'], inplace=True)
quiz_encoded.drop(['time_Q1', 'dclick_Q1'], axis=1, inplace=True)

# Split dataset - _test used as validation set
X = quiz_encoded.loc[:, quiz_encoded.columns != 'Flag']
y = quiz_encoded.loc[:, 'Flag']
X_train, X_test, y_train, y_test = train_test_split(X, y, stratify=y, random_state=123)

# Handle imbalances
weight_flag = compute_class_weight('balanced', np.unique(y_train), y_train)
weights = np.ones(quiz_encoded.shape[0], dtype = 'float')
weights[quiz_encoded.Flag == 'Bad'] = weight_flag[0] - 1
weights[quiz_encoded.Flag == 'Good'] = weight_flag[1] - 1
weights[quiz_encoded.Flag == 'Unknown'] = weight_flag[2] - 1

# Baseline model
baseline = DummyClassifier(strategy="stratified")
baseline.fit(X_train, y_train)
y_pred = baseline.predict(X_test)
print(confusion_matrix(y_test, y_pred))
print(classification_report(y_test, y_pred))

# Using xgboost as state-of-the-art in classification, and resilient to NaN values
xgb_model = xgb.XGBClassifier(objective='multi:softprob')
# xgb_model.fit(X_train, y_train,  sample_weight=weights, eval_metric='merror')

# To speed up, reduced number of potential alternative parameters
params = {
    "learning_rate": [0.01, 0.05, 0.10, 0.15, 0.30],
    "gamma": [0, 0.1, 0.2, 0.3, 0.5],
    "max_depth": [2, 3, 6],
    "n_estimators": [10, 25, 50, 100]
}

search = RandomizedSearchCV(xgb_model, param_distributions=params,
                            random_state=123, n_iter=100, cv=5, verbose=2, n_jobs=4,
                            scoring='balanced_accuracy', return_train_score=True)

search.fit(X_train, y_train,  sample_weight=weights, eval_metric='merror')
report_best_scores(search.cv_results_, 1)

best_model = search.best_estimator_
pickle.dump(best_model, open("assets/best_model.pickle.dat", "wb"))

# Evaluation and feature importance
xgb.plot_importance(best_model, max_num_features=20)

y_pred = best_model.predict(X_test)
print(confusion_matrix(y_test, y_pred))
print(classification_report(y_test, y_pred))
