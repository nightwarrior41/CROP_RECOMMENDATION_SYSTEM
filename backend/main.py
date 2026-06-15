from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import joblib
import pandas as pd
import os
import json
from datetime import datetime, timedelta
from meteostat import Point, daily
from sqlalchemy.orm import Session

from database import engine, get_db
import db_models

# Create DB tables
db_models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Agro Intelligence API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Load Models ---
# 1. Classification Model
model_path = os.path.join(os.path.dirname(__file__), "crop_model.pkl")
try:
    model = joblib.load(model_path)
except Exception as e:
    model = None
    print(f"Warning: Could not load the model from {model_path}. Error: {e}")

# 2. Profit Regressor Model
profit_model_path = os.path.join(os.path.dirname(__file__), "profit_model.pkl")
try:
    profit_data = joblib.load(profit_model_path)
    profit_model = profit_data['model']
    profit_features = profit_data['features']
except Exception as e:
    profit_model = None
    profit_features = None
    print(f"Warning: Could not load the profit model from {profit_model_path}. Error: {e}")


# --- Schemas ---
class CropInput(BaseModel):
    temperature: float = Field(..., ge=-10, le=60, description="Temperature in Celsius")
    humidity: float = Field(..., ge=0, le=100, description="Humidity percentage")
    rainfall: float = Field(..., ge=0, le=500, description="Rainfall in mm")
    nitrogen: float = Field(..., ge=0, le=200, description="Nitrogen content")
    phosphorus: float = Field(..., ge=0, le=200, description="Phosphorus content")
    potassium: float = Field(..., ge=0, le=200, description="Potassium content")
    ph: float = Field(..., ge=3, le=10, description="Soil pH value")

class ProfitPredictInput(BaseModel):
    temperature: float
    humidity: float
    rainfall: float
    soil_type: str = "Loam"

CROP_IDEALS = {
    "apple": {"N": 20.8, "P": 134.22, "K": 199.89, "temp": 22.63, "hum": 92.33, "ph": 5.93, "rain": 112.65},
    "banana": {"N": 100.23, "P": 82.01, "K": 50.05, "temp": 27.38, "hum": 80.36, "ph": 5.98, "rain": 104.63},
    "blackgram": {"N": 40.02, "P": 67.47, "K": 19.24, "temp": 29.97, "hum": 65.12, "ph": 7.13, "rain": 67.88},
    "chickpea": {"N": 40.09, "P": 67.79, "K": 79.92, "temp": 18.87, "hum": 16.86, "ph": 7.34, "rain": 80.06},
    "coconut": {"N": 21.98, "P": 16.93, "K": 30.59, "temp": 27.41, "hum": 94.84, "ph": 5.98, "rain": 175.69},
    "coffee": {"N": 101.2, "P": 28.74, "K": 29.94, "temp": 25.54, "hum": 58.87, "ph": 6.79, "rain": 158.07},
    "cotton": {"N": 117.77, "P": 46.24, "K": 19.56, "temp": 23.99, "hum": 79.84, "ph": 6.91, "rain": 80.4},
    "grapes": {"N": 23.18, "P": 132.53, "K": 200.11, "temp": 23.85, "hum": 81.88, "ph": 6.03, "rain": 69.61},
    "jute": {"N": 78.4, "P": 46.86, "K": 39.99, "temp": 24.96, "hum": 79.64, "ph": 6.73, "rain": 174.79},
    "kidneybeans": {"N": 20.75, "P": 67.54, "K": 20.05, "temp": 20.12, "hum": 21.61, "ph": 5.75, "rain": 105.92},
    "lentil": {"N": 18.77, "P": 68.36, "K": 19.41, "temp": 24.51, "hum": 64.8, "ph": 6.93, "rain": 45.68},
    "maize": {"N": 77.76, "P": 48.44, "K": 19.79, "temp": 22.39, "hum": 65.09, "ph": 6.25, "rain": 84.77},
    "mango": {"N": 20.07, "P": 27.18, "K": 29.92, "temp": 31.21, "hum": 50.16, "ph": 5.77, "rain": 94.7},
    "mothbeans": {"N": 21.44, "P": 48.01, "K": 20.23, "temp": 28.19, "hum": 53.16, "ph": 6.83, "rain": 51.2},
    "mungbean": {"N": 20.99, "P": 47.28, "K": 19.87, "temp": 28.53, "hum": 85.5, "ph": 6.72, "rain": 48.4},
    "muskmelon": {"N": 100.32, "P": 17.72, "K": 50.08, "temp": 28.66, "hum": 92.34, "ph": 6.36, "rain": 24.69},
    "orange": {"N": 19.58, "P": 16.55, "K": 10.01, "temp": 22.77, "hum": 92.17, "ph": 7.02, "rain": 110.47},
    "papaya": {"N": 49.88, "P": 59.05, "K": 50.04, "temp": 33.72, "hum": 92.4, "ph": 6.74, "rain": 142.63},
    "pigeonpeas": {"N": 20.73, "P": 67.73, "K": 20.29, "temp": 27.74, "hum": 48.06, "ph": 5.79, "rain": 149.46},
    "pomegranate": {"N": 18.87, "P": 18.75, "K": 40.21, "temp": 21.84, "hum": 90.13, "ph": 6.43, "rain": 107.53},
    "rice": {"N": 79.89, "P": 47.58, "K": 39.87, "temp": 23.69, "hum": 82.27, "ph": 6.43, "rain": 236.18},
    "watermelon": {"N": 99.42, "P": 17.0, "K": 50.22, "temp": 25.59, "hum": 85.16, "ph": 6.5, "rain": 50.79},
    "tomato": {"N": 50, "P": 50, "K": 50, "temp": 25, "hum": 70, "ph": 6.0, "rain": 100},
    "saffron": {"N": 20, "P": 20, "K": 20, "temp": 15, "hum": 40, "ph": 7.0, "rain": 40},
}


SUPPORTED_CROPS = list(CROP_IDEALS.keys())

def generate_monthly_distribution(annual_profit: float) -> list:
    # A simple pseudo-seasonal distribution curve
    dist = [0.03, 0.04, 0.07, 0.12, 0.18, 0.15, 0.12, 0.08, 0.07, 0.06, 0.05, 0.03]
    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    return [{"month": m, "profit": int(annual_profit * d)} for m, d in zip(months, dist)]

def get_crop_category(crop: str) -> str:
    cereal = ["rice", "wheat", "maize"]
    vegetable = ["tomato", "potato"]
    spice = ["saffron", "chickpea"]
    fruit = ["apple", "banana", "coconut", "grapes", "mango", "muskmelon", "orange", "papaya", "pomegranate", "watermelon"]
    
    if crop in cereal: return "Cereal"
    if crop in vegetable: return "Vegetable"
    if crop in spice: return "Spice"
    if crop in fruit: return "Fruit"
    return "Other"

def get_crop_emoji(crop: str) -> str:
    name = crop.lower()
    if 'wheat' in name: return '🌾'
    if 'rice' in name: return '🌿'
    if 'corn' in name or 'maize' in name: return '🌽'
    if 'tomato' in name: return '🍅'
    if 'potato' in name: return '🥔'
    if 'saffron' in name: return '🌺'
    if 'apple' in name: return '🍎'
    return '🌱'

@app.post("/predict")
async def predict_crop(data: CropInput):
    if model is None:
        raise HTTPException(status_code=503, detail="Model unavailable.")
    
    try:
        input_df = pd.DataFrame([{
            'N': data.nitrogen, 'P': data.phosphorus, 'K': data.potassium,
            'temperature': data.temperature, 'humidity': data.humidity,
            'ph': data.ph, 'rainfall': data.rainfall
        }])
        
        probabilities = model.predict_proba(input_df)[0]
        class_probs = sorted(zip(model.classes_, probabilities), key=lambda x: x[1], reverse=True)[:5]
        
        predictions = []
        for crop, prob in class_probs:
            ideal = CROP_IDEALS.get(crop.lower(), {})
            
            # Simple similarity calculation (1 - percentage difference)
            def similarity(val, target, weight=1.0):
                if target == 0: return 1.0
                diff = abs(val - target) / target
                return max(0, 1 - (diff * weight))

            # Climate Match (Temp, Hum, Rain)
            c_m = (similarity(data.temperature, ideal.get('temp', 25)) + 
                   similarity(data.humidity, ideal.get('hum', 70)) + 
                   similarity(data.rainfall, ideal.get('rain', 100))) / 3.0
            
            # Soil Match (N, P, K, pH)
            s_m = (similarity(data.nitrogen, ideal.get('N', 50)) + 
                   similarity(data.phosphorus, ideal.get('P', 50)) + 
                   similarity(data.potassium, ideal.get('K', 50)) + 
                   similarity(data.ph, ideal.get('ph', 6.5))) / 4.0
            
            reasoning = f"Excellent fit for your land."
            if s_m > 0.9 and c_m > 0.9:
                reasoning = f"{crop.capitalize()} is perfectly compatible with your current soil chemistry and climate."
            elif s_m > c_m:
                reasoning = f"Your soil profile is a strong match for {crop}, though weather conditions are slightly varied."
            else:
                reasoning = f"Current climate is ideal for {crop}, while soil nutrients could be optimized for max yield."

            predictions.append({
                "crop": crop,
                "confidence": float(prob),
                "climate_match": round(c_m, 2),
                "soil_match": round(s_m, 2),
                "reasoning": reasoning,
                "ideal_stats": ideal
            })
            
        return {"predictions": predictions}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/predict-profit")
async def get_profits(data: ProfitPredictInput, db: Session = Depends(get_db)):
    """Predicts profitability for all supported crops."""
    if profit_model is None:
        raise HTTPException(status_code=503, detail="Profit Model unavailable.")
        
    try:
        # We need to construct a dataframe matching profit_features exactly
        input_data = []
        for crop in SUPPORTED_CROPS:
            # Create base dictionary filled with 0s
            row = {feat: 0 for feat in profit_features}
            
            row['Temperature'] = data.temperature
            row['Humidity'] = data.humidity
            row['Rainfall'] = data.rainfall
            
            # One-hot encode manually for this row
            if f"Crop_{crop}" in profit_features:
                row[f"Crop_{crop}"] = 1
            if f"Soil_Type_{data.soil_type}" in profit_features:
                row[f"Soil_Type_{data.soil_type}"] = 1
                
            input_data.append(row)
            
        input_df = pd.DataFrame(input_data)
        
        # Predict: ['Profit', 'Market_Price', 'Production_Cost', 'Yield']
        predictions = profit_model.predict(input_df)
        
        results = []
        
        for crop, pred in zip(SUPPORTED_CROPS, predictions):
            profit, price, cost, crop_yield = pred
            
            results.append({
                "cropName": crop.capitalize(),
                "emoji": get_crop_emoji(crop),
                "profitPerHectare": max(0, float(profit)),
                "marketPrice": max(0, float(price)),
                "productionCost": max(0, float(cost)),
                "growthPercent": float(round((profit - cost) / max(1, cost) * 100, 2)),
                "category": get_crop_category(crop),
                "monthlyData": generate_monthly_distribution(max(0, float(profit))),
                "yield": max(0, float(crop_yield))
            })
            
        # Log to db history if you want, but for recommend-crops is better.
        return results
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Prediction failed")

@app.post("/recommend-crops")
async def recommend_crops(data: ProfitPredictInput, db: Session = Depends(get_db)):
    """Predicts profit and provides ranking + recommendations."""
    if profit_model is None:
        raise HTTPException(status_code=503, detail="Profit Model unavailable.")
    
    # Run the predict profit logic internally
    results = await get_profits(data, db)
    
    # Sort by profit
    sorted_results = sorted(results, key=lambda x: x["profitPerHectare"], reverse=True)
    
    # Store top prediction into history
    if len(sorted_results) > 0:
        top = sorted_results[0]
        history_entry = db_models.PredictionHistory(
            crop_name=top["cropName"],
            temperature=data.temperature,
            humidity=data.humidity,
            rainfall=data.rainfall,
            predicted_profit=top["profitPerHectare"],
            predicted_yield=top["yield"],
            recommendations_json=json.dumps([r["cropName"] for r in sorted_results[1:4]])
        )
        db.add(history_entry)
        db.commit()
    
    return {"ranking": sorted_results}

@app.get("/weather-analysis")
async def get_weather_analysis(lat: float, lon: float):
    return {"message": "Weather analysis simulated."}

@app.get("/")
async def root():
    return {"message": "Welcome to the Agro Intelligence API."}
