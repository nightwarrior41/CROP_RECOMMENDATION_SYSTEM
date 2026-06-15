import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Simulates the ML backend + Weather API service.
/// In production: replace with real API calls to your Python ML microservice
/// and OpenWeatherMap / Visual Crossing historical weather API.
class AgroService {
  static final _rng = Random();

  // ── Weather ──────────────────────────────────────────────────────────────

  static Future<WeatherData> fetchCurrentWeather(
      double lat, double lon) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const WeatherData(
      temperature: 24.5,
      humidity: 68,
      rainfall: 12.3,
      windSpeed: 14.2,
      condition: 'Partly Cloudy',
      icon: '⛅',
      location: 'Punjab, India',
    );
  }

  static Future<List<HistoricalWeather>> fetchHistoricalWeather(
      double lat, double lon) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    return List.generate(12, (i) {
      final year = 2013 + i;
      return HistoricalWeather(
        year: year,
        avgTemp: 22.0 + _rng.nextDouble() * 4,
        totalRainfall: 800 + _rng.nextDouble() * 400,
        frostDays: _rng.nextInt(10),
        droughtDays: 20 + _rng.nextInt(30),
      );
    });
  }

  // ── Crop Prediction (ML) ─────────────────────────────────────────────────

  static Future<List<CropPrediction>> predictCrops(
      double lat, double lon, String landType) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return const [
      CropPrediction(
        cropName: 'Wheat',
        confidence: 0.91,
        emoji: '🌾',
        season: 'Rabi (Oct–Mar)',
        expectedYield: 4.2,
        requirements: ['Moderate rainfall', 'Cool winters', 'Clay-loam soil'],
        soilType: 'Clay-Loam',
      ),
      CropPrediction(
        cropName: 'Rice',
        confidence: 0.84,
        emoji: '🌿',
        season: 'Kharif (Jun–Nov)',
        expectedYield: 5.8,
        requirements: ['High water', 'Warm humid', 'Alluvial soil'],
        soilType: 'Alluvial',
      ),
      CropPrediction(
        cropName: 'Maize',
        confidence: 0.76,
        emoji: '🌽',
        season: 'Kharif (Jun–Sep)',
        expectedYield: 3.9,
        requirements: ['Moderate water', 'Warm days', 'Well-drained loam'],
        soilType: 'Loam',
      ),
      CropPrediction(
        cropName: 'Soybean',
        confidence: 0.68,
        emoji: '🫘',
        season: 'Kharif (Jun–Oct)',
        expectedYield: 2.4,
        requirements: ['Moderate rainfall', 'Warm climate', 'Black soil'],
        soilType: 'Black',
      ),
      CropPrediction(
        cropName: 'Mustard',
        confidence: 0.62,
        emoji: '🌻',
        season: 'Rabi (Oct–Feb)',
        expectedYield: 1.8,
        requirements: ['Low moisture', 'Cool dry winters', 'Sandy-loam'],
        soilType: 'Sandy-Loam',
      ),
    ];
  }

  // ── Profit Analysis ───────────────────────────────────────────────────────

  static Future<List<CropProfit>> fetchCropProfits({
    double temp = 25.0, 
    double hum = 70.0, 
    double rain = 100.0, 
    String soilType = "Loam"
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/recommend-crops'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "temperature": temp,
          "humidity": hum,
          "rainfall": rain,
          "soil_type": soilType,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List ranking = data['ranking'] ?? [];
        
        return ranking.map((item) {
          return CropProfit(
            cropName: item['cropName'],
            emoji: item['emoji'],
            profitPerHectare: (item['profitPerHectare'] as num).toDouble(),
            marketPrice: (item['marketPrice'] as num).toDouble(),
            productionCost: (item['productionCost'] as num).toDouble(),
            growthPercent: (item['growthPercent'] as num).toDouble(),
            category: item['category'],
            monthlyData: (item['monthlyData'] as List).map((m) => 
               MonthlyProfit(m['month'], (m['profit'] as num).toDouble())
            ).toList(),
          );
        }).toList();
      } else {
        throw Exception('Failed to load crop profits ML API: \${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching profits: \$e');
      throw Exception('Could not fetch ML profit predictions. Please ensure FastAPI backend is running.');
    }
  }

  // ── Best Crop Recommendation (ML over 10yr data) ─────────────────────────

  static Future<List<BestCropRecommendation>> getBestCropRecommendations(
      double lat, double lon) async {
    await Future.delayed(const Duration(milliseconds: 1800));
    return const [
      BestCropRecommendation(
        cropName: 'Wheat',
        emoji: '🌾',
        score: 94,
        climateMatch: 0.96,
        soilMatch: 0.93,
        profitability: 0.78,
        waterEfficiency: 0.88,
        reasoning:
            '12-year climate analysis shows consistent cool winters with 820mm annual rainfall — optimal for Rabi wheat. Soil moisture retention aligns with root development patterns.',
        pros: [
          'Climate perfectly matches wheat growing windows',
          'Government MSP guarantees stable income',
          'High mechanization potential reduces labor',
          'Strong local market demand',
        ],
        cons: [
          'Moderate profit margins vs. cash crops',
          'Susceptible to rust disease in humid years',
        ],
      ),
      BestCropRecommendation(
        cropName: 'Tomato',
        emoji: '🍅',
        score: 87,
        climateMatch: 0.81,
        soilMatch: 0.89,
        profitability: 0.96,
        waterEfficiency: 0.72,
        reasoning:
            'Drip-irrigated tomato cultivation shows 3x higher ROI. 10-year data shows 240+ sunny days ideal for fruit set. Market proximity adds premium pricing advantage.',
        pros: [
          'Highest profit per hectare in your region',
          'Year-round demand with cold storage',
          'Quick 3-4 month turnaround',
        ],
        cons: [
          'High water and labor requirement',
          'Price volatility during peak season',
          'Requires pest management investment',
        ],
      ),
      BestCropRecommendation(
        cropName: 'Soybean',
        emoji: '🫘',
        score: 79,
        climateMatch: 0.83,
        soilMatch: 0.75,
        profitability: 0.71,
        waterEfficiency: 0.91,
        reasoning:
            'Nitrogen-fixing soybean improves soil health after cereal crops. Climate analysis shows 110-day frost-free window aligns with soybean maturity period.',
        pros: [
          'Excellent for crop rotation with wheat',
          'Improves soil nitrogen naturally',
          'Low input cost, good ROI',
        ],
        cons: [
          'Lower absolute profit vs. vegetables',
          'Needs precise harvest timing',
        ],
      ),
    ];
  }

  // ── Smart Alerts ──────────────────────────────────────────────────────────

  static Future<List<WeatherAlert>> fetchSmartAlerts(
      double lat, double lon) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return const [
      WeatherAlert(
        title: 'Severe Storm Warning',
        description:
            'Thunderstorms with wind gusts up to 85 km/h expected tonight. Secure loose equipment and delay any spray operations.',
        severity: AlertSeverity.critical,
        time: 'Tonight, 8 PM – 2 AM',
        icon: '⛈️',
        isActive: true,
      ),
      WeatherAlert(
        title: 'Heavy Rainfall Alert',
        description:
            '80–120mm rainfall forecast over 48 hours. Waterlogging risk in low-lying fields. Consider drainage preparation.',
        severity: AlertSeverity.high,
        time: 'Tomorrow – Day after',
        icon: '🌧️',
        isActive: true,
      ),
      WeatherAlert(
        title: 'Frost Risk',
        description:
            'Temperature may drop to 2°C on Friday night. Young seedlings and flowering crops at risk. Consider protective covers.',
        severity: AlertSeverity.medium,
        time: 'Friday Night',
        icon: '🌨️',
        isActive: false,
      ),
      WeatherAlert(
        title: 'Heatwave Advisory',
        description:
            'Temperatures expected 4–5°C above seasonal average next week. Increase irrigation frequency and avoid midday fieldwork.',
        severity: AlertSeverity.medium,
        time: 'Next Week (Mon–Wed)',
        icon: '🌡️',
        isActive: false,
      ),
      WeatherAlert(
        title: 'Strong Wind',
        description:
            'Sustained winds 40–55 km/h. Pollination disruption risk for open-pollinated crops. Delay herbicide application.',
        severity: AlertSeverity.low,
        time: 'Wednesday Afternoon',
        icon: '💨',
        isActive: false,
      ),
      WeatherAlert(
        title: 'Pest Outbreak Conditions',
        description:
            'Warm humid conditions favorable for aphid and fungal disease spread. Scout fields and consider preventive application.',
        severity: AlertSeverity.low,
        time: 'This Week',
        icon: '🐛',
        isActive: false,
      ),
    ];
  }
}
