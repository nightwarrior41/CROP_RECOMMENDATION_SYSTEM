import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import GridSearchCV
import joblib

dataset = pd.read_csv(r'c:\Users\LENOVO\Crop-APP\Crop_recommendation.csv')
X = dataset[['temperature', 'humidity', 'ph', 'rainfall']]
y = dataset['label']
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

param_grid = {
    'n_estimators': [50, 100, 200],
    'max_depth': [None, 10, 20, 30],
    'min_samples_split': [2, 5, 10]
}
grid_search = GridSearchCV(estimator=RandomForestClassifier(random_state=42), 
                           param_grid=param_grid, 
                           cv=5, 
                           n_jobs=-1, 
                           scoring='accuracy')
grid_search.fit(X_train, y_train)

best_model = grid_search.best_estimator_
joblib.dump(best_model, r'c:\Users\LENOVO\Crop-APP\crop_model.pkl')
print("Model saved successfully as crop_model.pkl")
