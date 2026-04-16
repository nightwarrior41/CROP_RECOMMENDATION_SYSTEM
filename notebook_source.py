import numpy as np 
import pandas as pd
dataset = pd.read_csv('Crop_recommendation.csv')
dataset.head()

        dataset.shape
import matplotlib.pyplot as plt
import seaborn as sns

# Set up grid for subplots
features = ['temperature', 'humidity', 'ph', 'rainfall']

fig, axes = plt.subplots(2, 2, figsize=(12, 10))
fig.suptitle('Distribution of Environmental Features', fontsize=16)

for i, feature in enumerate(features):
    row, col = i // 2, i % 2
    sns.histplot(dataset[feature], kde=True, ax=axes[row, col], color='skyblue')
    axes[row, col].set_title(f'{feature.capitalize()} Distribution')
    axes[row, col].set_xlabel(feature)

plt.tight_layout(rect=[0, 0.03, 1, 0.95])
plt.show()
# Average features per crop to see which environment suits which crop best
avg_features = dataset.groupby('label')[features].mean()

fig, axes = plt.subplots(2, 2, figsize=(15, 12))
fig.suptitle('Average Environmental Requirements per Crop', fontsize=16)

for i, feature in enumerate(features):
    row, col = i // 2, i % 2
    avg_features[feature].sort_values().plot(kind='bar', ax=axes[row, col], color='lightgreen', edgecolor='black')
    axes[row, col].set_title(f'Average {feature.capitalize()} required by Crop')
    axes[row, col].set_ylabel(feature)
    axes[row, col].tick_params(axis='x', rotation=90)

plt.tight_layout(rect=[0, 0.03, 1, 0.95])
plt.show()
X = dataset[['temperature', 'humidity', 'ph', 'rainfall']]
y = dataset['label']
X.head()
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

print(f"Training data shape: {X_train.shape}")
print(f"Testing data shape: {X_test.shape}")
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report

# Initialize the model
model = RandomForestClassifier(random_state=42)

# Train the model
model.fit(X_train, y_train)

# Make predictions
y_pred = model.predict(X_test)

# Evaluate the model
accuracy = accuracy_score(y_test, y_pred)
print(f"Model Accuracy: {accuracy * 100:.2f}%")
print("\nClassification Report:")
print(classification_report(y_test, y_pred))
from sklearn.model_selection import GridSearchCV

# Define a grid of hyperparameters to test
param_grid = {
    'n_estimators': [50, 100, 200],
    'max_depth': [None, 10, 20, 30],
    'min_samples_split': [2, 5, 10]
}

# Initialize Grid Search, applying 5-fold cross-validation
grid_search = GridSearchCV(estimator=RandomForestClassifier(random_state=42), 
                           param_grid=param_grid, 
                           cv=5, 
                           n_jobs=-1, 
                           verbose=1,
                           scoring='accuracy')

# Fit Grid Search to the training data
grid_search.fit(X_train, y_train)

print(f"Best Parameters Found: {grid_search.best_params_}")
print(f"Best Cross-Validation Accuracy: {grid_search.best_score_ * 100:.2f}%")
# Retrieve the best model
best_model = grid_search.best_estimator_

# Predict on the test set
y_pred_tuned = best_model.predict(X_test)

# Evaluate the tuned model validation
tuned_accuracy = accuracy_score(y_test, y_pred_tuned)
print(f"Tuned Model Accuracy on Test Data: {tuned_accuracy * 100:.2f}%")
print("\nClassification Report (Tuned Model):")
print(classification_report(y_test, y_pred_tuned))
def make_prediction():
    print("\n--- Crop Recommendation System ---")
    print("Please enter the following environmental details:")
    
    try:
        temp = float(input("Temperature (in Celsius, e.g., 25.5): "))
        hum = float(input("Humidity (in %, e.g., 71.2): "))
        ph = float(input("pH value of the soil (e.g., 6.5): "))
        rain = float(input("Rainfall (in mm, e.g., 100.0): "))
        
        # Format input for the model
        input_data = pd.DataFrame(
            [[temp, hum, ph, rain]], 
            columns=['temperature', 'humidity', 'ph', 'rainfall']
        )
        
        # Make prediction
        prediction = best_model.predict(input_data)
        print("\n=========================================")
        print(f"  => Recommended Crop: {prediction[0].upper()} <=")
        print("=========================================")
        
    except ValueError:
        print("\n[Error] Invalid input detected. Please enter numerical values only.")

# Simply run the function to see the interactive prompts below:
make_prediction()
import joblib
joblib.dump(best_model, 'crop_model.pkl')
print("Model saved as crop_model.pkl")
import joblib
joblib.dump(best_model, 'crop_model.pkl')
print("Model saved as crop_model.pkl")