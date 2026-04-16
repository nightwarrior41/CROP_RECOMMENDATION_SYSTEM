from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import joblib
import pandas as pd
import os

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
    ph: float = Field(..., ge=0, le=14, description="Soil pH value")
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
            'ph': data.ph,
            'rainfall': data.rainfall
        }])
        
        # Predict class and probabilities
        prediction = model.predict(input_df)[0]
        probabilities = model.predict_proba(input_df)[0]
        
        # Get probability for the predicted class
        class_index = list(model.classes_).index(prediction)
        confidence = float(probabilities[class_index])
        
        return {
            "crop": str(prediction),
            "confidence": confidence
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
async def root():
    return {"message": "Welcome to the Agro Intelligence API. Send POST requests to /predict."}
