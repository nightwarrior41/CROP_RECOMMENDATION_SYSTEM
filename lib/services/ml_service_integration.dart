// ══════════════════════════════════════════════════════════════════════
//  ML Service — Production Integration Guide
//  Replace mock data in agro_service.dart with these real API calls
// ══════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:http/http.dart' as http;


/// ─── Python ML Backend Setup ─────────────────────────────────────────
///
/// 1. Train a RandomForest / XGBoost model on:
///    - Historical weather (Open-Meteo Archive API — free, 50yr data)
///    - Soil data (SoilGrids API by ISRIC — free)
///    - Crop yield data (FAO STAT API — free)
///
/// 2. Deploy as a FastAPI service:
///    POST /predict-crops   → returns ranked crop predictions
///    POST /best-crop       → returns ML-scored recommendations
///    GET  /crop-profits    → returns market data
///
/// 3. Weather API used:
///    - Current: OpenWeatherMap API (https://openweathermap.org/api)
///    - Historical (10yr): Open-Meteo Archive (https://open-meteo.com/en/docs/historical-weather-api)
///    - Alerts: OpenWeatherMap One Call API 3.0
///
/// ─── API Keys Required ───────────────────────────────────────────────
///    OPENWEATHER_API_KEY  — https://openweathermap.org
///    AGRO_ML_BASE_URL     — Your FastAPI deployment URL

const String _mlBaseUrl = 'https://your-ml-api.com';
const String _owmKey = 'YOUR_OPENWEATHERMAP_KEY';
const String _openMeteoHistoricalUrl = 'https://archive-api.open-meteo.com/v1/archive';

class ProductionAgroService {

  /// ─── Current Weather ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchCurrentWeather(
      double lat, double lon) async {
    final uri = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
      '?lat=$lat&lon=$lon&appid=$_owmKey&units=metric',
    );
    final res = await http.get(uri);
    return jsonDecode(res.body);
  }

  /// ─── Weather Alerts (One Call API 3.0) ───────────────────────────
  static Future<Map<String, dynamic>> fetchWeatherAlerts(
      double lat, double lon) async {
    final uri = Uri.parse(
      'https://api.openweathermap.org/data/3.0/onecall'
      '?lat=$lat&lon=$lon&exclude=minutely,hourly&appid=$_owmKey&units=metric',
    );
    final res = await http.get(uri);
    final data = jsonDecode(res.body);
    // data['alerts'] contains the storm/rain/snow alert list
    return data;
  }

  /// ─── 10-Year Historical Weather (Open-Meteo — FREE) ─────────────
  ///
  /// Open-Meteo Archive provides daily data from 1940 to present.
  /// No API key required!
  static Future<List<Map<String, dynamic>>> fetchTenYearHistory(
      double lat, double lon) async {
    final endYear = DateTime.now().year - 1;
    final startYear = endYear - 10;

    final uri = Uri.parse(
      '$_openMeteoHistoricalUrl'
      '?latitude=$lat&longitude=$lon'
      '&start_date=$startYear-01-01'
      '&end_date=$endYear-12-31'
      '&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,windspeed_10m_max'
      '&timezone=auto',
    );
    final res = await http.get(uri);
    final data = jsonDecode(res.body);

    // Aggregate daily → yearly summary
    // data['daily']['time'], data['daily']['precipitation_sum'], etc.
    return _aggregateToYearly(data['daily']);
  }

  static List<Map<String, dynamic>> _aggregateToYearly(
      Map<String, dynamic> daily) {
    final times = List<String>.from(daily['time']);
    final rain = List<double>.from(
        daily['precipitation_sum'].map((v) => (v ?? 0.0) as double));
    final tempMax = List<double>.from(
        daily['temperature_2m_max'].map((v) => (v ?? 0.0) as double));

    final Map<int, List<double>> yearlyRain = {};
    final Map<int, List<double>> yearlyTemp = {};

    for (int i = 0; i < times.length; i++) {
      final year = int.parse(times[i].split('-')[0]);
      yearlyRain.putIfAbsent(year, () => []).add(rain[i]);
      yearlyTemp.putIfAbsent(year, () => []).add(tempMax[i]);
    }

    return yearlyRain.entries.map((e) {
      final year = e.key;
      final totalRain = e.value.reduce((a, b) => a + b);
      final avgTemp = yearlyTemp[year]!.reduce((a, b) => a + b) /
          yearlyTemp[year]!.length;
      return {
        'year': year,
        'totalRainfall': totalRain,
        'avgTemp': avgTemp,
      };
    }).toList()
      ..sort((a, b) => (a['year'] as int).compareTo(b['year'] as int));
  }

  /// ─── ML Crop Prediction (FastAPI backend) ────────────────────────
  ///
  /// Your Python backend should:
  /// 1. Accept: lat, lon, soil_type, current_weather_features
  /// 2. Query SoilGrids for soil properties at location
  /// 3. Feed into trained XGBoost model
  /// 4. Return ranked crop predictions with confidence scores
  static Future<List<Map<String, dynamic>>> predictCrops(
      double lat,
      double lon,
      String soilType,
      Map<String, dynamic> weatherFeatures) async {
    final res = await http.post(
      Uri.parse('$_mlBaseUrl/predict-crops'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'latitude': lat,
        'longitude': lon,
        'soil_type': soilType,
        'weather': weatherFeatures,
      }),
    );
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['predictions']);
  }

  /// ─── Best Crop (ML over 10yr data) ───────────────────────────────
  ///
  /// Python backend flow:
  /// 1. Pull 10yr weather from Open-Meteo (cached)
  /// 2. Compute climate fingerprint (temperature seasonality, GDD, etc.)
  /// 3. Score each crop using trained multi-output classifier
  /// 4. Return ranked list with dimension scores
  static Future<List<Map<String, dynamic>>> getBestCrops(
      double lat, double lon) async {
    final res = await http.post(
      Uri.parse('$_mlBaseUrl/best-crop'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'latitude': lat, 'longitude': lon}),
    );
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['recommendations']);
  }

  /// ─── Soil Type from GPS (SoilGrids API — FREE) ───────────────────
  ///
  /// ISRIC SoilGrids provides high-resolution global soil data
  /// No API key required for basic usage
  static Future<String> getSoilType(double lat, double lon) async {
    final uri = Uri.parse(
      'https://rest.isric.org/soilgrids/v2.0/properties/query'
      '?lon=$lon&lat=$lat&property=wrbgroup&depth=0-5cm&value=mean',
    );
    final res = await http.get(uri);
    final data = jsonDecode(res.body);
    // Parse WRB soil classification from response
    return data['properties']['layers'][0]['depths'][0]['values']['mean']
            ?.toString() ??
        'Loam';
  }
}

// ══════════════════════════════════════════════════════════════════════
//  Python ML Backend Starter (FastAPI)
//  Save as: backend/main.py
// ══════════════════════════════════════════════════════════════════════
/*
from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import numpy as np

app = FastAPI(title="AgroMind ML API")

# Load pre-trained models
crop_predictor = joblib.load("models/crop_predictor_xgb.pkl")
best_crop_model = joblib.load("models/best_crop_rf.pkl")
label_encoder = joblib.load("models/label_encoder.pkl")

CROPS = ["Wheat", "Rice", "Maize", "Soybean", "Mustard", 
         "Tomato", "Potato", "Saffron", "Cotton", "Sugarcane"]

class PredictRequest(BaseModel):
    latitude: float
    longitude: float
    soil_type: str
    weather: dict

class BestCropRequest(BaseModel):
    latitude: float
    longitude: float

@app.post("/predict-crops")
async def predict_crops(req: PredictRequest):
    features = extract_features(req.weather, req.soil_type)
    probabilities = crop_predictor.predict_proba([features])[0]
    predictions = sorted(
        zip(CROPS, probabilities), key=lambda x: x[1], reverse=True
    )[:5]
    return {
        "predictions": [
            {"crop_name": name, "confidence": float(conf)}
            for name, conf in predictions
        ]
    }

@app.post("/best-crop")
async def best_crop(req: BestCropRequest):
    # Fetch 10yr historical data
    historical = fetch_openmeteo_history(req.latitude, req.longitude)
    climate_features = compute_climate_fingerprint(historical)
    scores = best_crop_model.predict(climate_features)
    return {"recommendations": scores}

def extract_features(weather: dict, soil_type: str) -> np.ndarray:
    soil_encoding = {"Loam": 0, "Clay": 1, "Sandy": 2, "Black": 3, "Alluvial": 4}
    return np.array([
        weather.get("temperature", 25),
        weather.get("humidity", 60),
        weather.get("rainfall", 800),
        weather.get("wind_speed", 10),
        soil_encoding.get(soil_type, 0),
    ])
*/
