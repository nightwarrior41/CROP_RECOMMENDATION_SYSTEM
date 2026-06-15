import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
import joblib
import os

def create_synthetic_profit_data(base_data_path):
    # Load base crop recommendation dataset if available to get realistic crops
    if os.path.exists(base_data_path):
        base_df = pd.read_csv(base_data_path)
    else:
        # Fallback if not found
        base_df = pd.DataFrame({
            'label': ['rice', 'wheat', 'maize', 'chickpea', 'kidneybeans', 'pigeonpeas', 'mothbeans', 'mungbean', 'blackgram', 'lentil', 'pomegranate', 'banana', 'mango', 'grapes', 'watermelon', 'muskmelon', 'apple', 'orange', 'papaya', 'coconut', 'cotton', 'jute', 'coffee'],
            'temperature': [25.0] * 23,
            'humidity': [70.0] * 23,
            'rainfall': [100.0] * 23,
        })
        
    np.random.seed(42)
    
    # We will generate a synthetic dataset with the required columns
    crops = base_df['label'].unique()
    
    data = []
    
    # Base metrics for different crops to make it somewhat realistic
    crop_base_metrics = {
        'rice': {'cost': 1200, 'price': 320, 'yield': 5.5},
        'wheat': {'cost': 920, 'price': 280, 'yield': 4.2},
        'maize': {'cost': 680, 'price': 180, 'yield': 3.9},
        'tomato': {'cost': 2400, 'price': 650, 'yield': 25.0},
        'saffron': {'cost': 6800, 'price': 3200, 'yield': 0.1},
    }
    
    # Ensure all crops have some base metrics
    for crop in crops:
        if crop not in crop_base_metrics:
            # Generate random base metrics for other crops
            crop_base_metrics[crop] = {
                'cost': np.random.uniform(500, 3000),
                'price': np.random.uniform(150, 1000),
                'yield': np.random.uniform(2.0, 15.0)
            }
            
    # Add tomato and saffron manually if not in crops
    for added_crop in ['tomato', 'saffron']:
        if added_crop not in crops:
            crops = np.append(crops, added_crop)
            
    num_samples = 2000
    
    for _ in range(num_samples):
        # Pick random crop
        crop = np.random.choice(crops)
        base = crop_base_metrics[crop]
        
        # Add some noise based on weather
        temp = np.random.uniform(10, 40)
        humidity = np.random.uniform(30, 90)
        rainfall = np.random.uniform(40, 250)
        
        # Determine soil type
        soil_type = np.random.choice(['Loam', 'Sandy', 'Clay', 'Alluvial', 'Black'])
        
        # Calculate variations based on conditions (synthetic logic)
        weather_factor = 1.0
        if 20 <= temp <= 30 and 50 <= humidity <= 80:
            weather_factor *= 1.2
            
        final_yield = base['yield'] * weather_factor * np.random.uniform(0.8, 1.2)
        final_cost = base['cost'] * np.random.uniform(0.9, 1.1)
        final_price = base['price'] * np.random.uniform(0.8, 1.3)
        
        # Profit = Expected Revenue - Cost
        revenue = final_yield * final_price
        profit = revenue - final_cost
        
        data.append({
            'Crop': crop,
            'Soil_Type': soil_type,
            'Temperature': temp,
            'Humidity': humidity,
            'Rainfall': rainfall,
            'Production_Cost': final_cost,
            'Market_Price': final_price,
            'Yield': final_yield,
            'Profit': profit
        })
        
    df = pd.DataFrame(data)
    return df

def train_and_save_model():
    print("Generating synthetic data...")
    df = create_synthetic_profit_data('../Crop_recommendation.csv')
    
    # We will train a model to predict Profit, Market_Price, Production_Cost, and Yield given Crop and Weather
    # Encode categorical features
    df_encoded = pd.get_dummies(df, columns=['Crop', 'Soil_Type'], drop_first=False)
    
    X = df_encoded.drop(['Production_Cost', 'Market_Price', 'Yield', 'Profit'], axis=1)
    # Using multiple targets
    y = df_encoded[['Profit', 'Market_Price', 'Production_Cost', 'Yield']]
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    print("Training Random Forest Regressor...")
    model = RandomForestRegressor(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    
    # Calculate R2 score
    score = model.score(X_test, y_test)
    print(f"Model trained successfully. R2 Score: {score:.4f}")
    
    # Ensure X columns are saved to match during inference
    model_data = {
        'model': model,
        'features': X.columns.tolist()
    }
    
    model_path = os.path.join(os.path.dirname(__file__), 'profit_model.pkl')
    joblib.dump(model_data, model_path)
    print(f"Model saved to {model_path}")

if __name__ == "__main__":
    train_and_save_model()
