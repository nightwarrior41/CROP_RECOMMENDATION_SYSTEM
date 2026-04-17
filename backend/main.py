from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import joblib
import pandas as pd
import os
from datetime import datetime, timedelta
from meteostat import Point, daily

app = FastAPI(title="Agro Intelligence Crop Prediction API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load the model at startup
model_path = os.path.join(os.path.dirname(__file__), "crop_model.pkl")

try:
    model = joblib.load(model_path)
except Exception as e:
    model = None
    print(f"Warning: Could not load the model from {model_path}. Error: {e}")

class CropInput(BaseModel):
    temperature: float = Field(..., ge=-10, le=60, description="Temperature in Celsius")
    humidity: float = Field(..., ge=0, le=100, description="Humidity percentage")
    rainfall: float = Field(..., ge=0, le=500, description="Rainfall in mm")

@app.post("/predict")
async def predict_crop(data: CropInput):
    if model is None:
        raise HTTPException(status_code=503, detail="Prediction model is not available. Please ensure crop_model.pkl is present.")
    
    try:
        # Construct DataFrame ensuring correct feature order
        input_df = pd.DataFrame([{
            'temperature': data.temperature,
            'humidity': data.humidity,
            'rainfall': data.rainfall
        }])
        
        # Predict probabilities
        probabilities = model.predict_proba(input_df)[0]
        
        # Create a list of (class_name, probability)
        class_probs = [(str(c), float(p)) for c, p in zip(model.classes_, probabilities)]
        
        # Sort by probability descending and get top 5
        class_probs.sort(key=lambda x: x[1], reverse=True)
        top_5 = class_probs[:5]
        
        predictions = [{"crop": crop, "confidence": prob} for crop, prob in top_5]
        
        return {
            "predictions": predictions
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/weather-analysis")
async def get_weather_analysis(lat: float, lon: float):
    try:
        # Define time period (last 90 days)
        end = datetime.now()
        start = end - timedelta(days=90)
        
        # Get weather data from Meteostat
        location = Point(lat, lon)
        data = daily(location, start, end)
        df = data.fetch()
        
        if df is None or df.empty:
            # Fallback mock data if no real data is found for this point
            return {
                "avg_temp": 24.5,
                "avg_humidity": 68.0,
                "total_rainfall": 12.3,
                "history": []
            }
        
        # Calculate aggregates
        # tavg: Average Temperature, rhum: Relative Humidity, prcp: Precipitation
        avg_temp = 25.0
        if 'tavg' in df.columns:
            mean_temp = df['tavg'].mean()
            if not pd.isna(mean_temp):
                avg_temp = float(mean_temp)
                
        avg_humidity = 70.0
        if 'rhum' in df.columns:
            mean_hum = df['rhum'].mean()
            if not pd.isna(mean_hum):
                avg_humidity = float(mean_hum)
                
        total_rainfall = 0.0
        if 'prcp' in df.columns:
            sum_rain = df['prcp'].sum()
            if not pd.isna(sum_rain):
                total_rainfall = float(sum_rain)
        
        # Prepare history for chart
        history = []
        for index, row in df.iterrows():
            # Send simplified data for the chart
            history.append({
                "date": index.strftime('%b %d'),
                "temp": float(row['tavg']) if 'tavg' in df.columns and not pd.isna(row['tavg']) else 25.0,
                "rainfall": float(row['prcp']) if 'prcp' in df.columns and not pd.isna(row['prcp']) else 0.0
            })
        
        # Filter for display (e.g., every 3rd day or last 30 points)
        if len(history) > 30:
            history = history[::3]
            
        return {
            "avg_temp": round(avg_temp, 1),
            "avg_humidity": round(avg_humidity, 1),
            "total_rainfall": round(total_rainfall, 1),
            "history": history
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Meteostat error: {str(e)}")

@app.get("/")
async def root():
    return {"message": "Welcome to the Agro Intelligence API. Send POST requests to /predict."}
