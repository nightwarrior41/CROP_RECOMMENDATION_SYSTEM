import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class CropPredictionService {
  // Configurable base URL
  // Use 'http://10.0.2.2:8000' for Android Emulator local testing
  // Replace with your Render URL (e.g., 'https://agro-api.onrender.com') when deployed
  static String baseUrl = 'http://10.0.2.2:8000';

  static Future<CropPrediction> predictCrop({
    required double temperature,
    required double humidity,
    required double ph,
    required double rainfall,
  }) async {
    final url = Uri.parse('$baseUrl/predict');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'temperature': temperature,
          'humidity': humidity,
          'ph': ph,
          'rainfall': rainfall,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String cropNameStr = data['crop'] as String;
        // Capitalize for display
        String cropTitle = "\${cropNameStr[0].toUpperCase()}\${cropNameStr.substring(1)}";
        
        return CropPrediction(
          cropName: cropTitle,
          confidence: (data['confidence'] as num).toDouble(),
          emoji: _getEmojiForCrop(cropNameStr),
          season: 'All Season (Based on current inputs)',
          expectedYield: 4.5, // Dummy average
          requirements: [
             'Temp: \${temperature.toStringAsFixed(1)}°C',
             'Humidity: \${humidity.toStringAsFixed(1)}%',
             'pH Level: \${ph.toStringAsFixed(1)}',
             'Rainfall: \${rainfall.toStringAsFixed(1)}mm'
          ],
          soilType: _getSoilForPH(ph),
        );
      } else {
        // Handling FastAPI validation or custom errors
        final errorData = jsonDecode(response.body);
        String errorDetail = 'Server returned error \${response.statusCode}';
        if (errorData['detail'] != null) {
            if (errorData['detail'] is List) {
                // Pydantic validation error lists
                errorDetail = errorData['detail'][0]['msg'] ?? 'Validation Error';
            } else {
                errorDetail = errorData['detail'].toString();
            }
        }
        throw Exception(errorDetail);
      }
    } on SocketException {
      throw Exception('Network error. Is the server running?');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on FormatException {
      throw Exception('Invalid server response format.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static String _getEmojiForCrop(String crop) {
    if (crop.contains('rice')) return '🌾';
    if (crop.contains('maize')) return '🌽';
    if (crop.contains('cotton')) return '🌱';
    if (crop.contains('apple')) return '🍎';
    if (crop.contains('orange')) return '🍊';
    if (crop.contains('grapes')) return '🍇';
    if (crop.contains('mango')) return '🥭';
    if (crop.contains('banana')) return '🥭';
    if (crop.contains('coffee')) return '☕';
    if (crop.contains('coconut')) return '☕';
    if (crop.contains('watermelon')) return '🥥';
    return '🌿';
  }

  static String _getSoilForPH(double ph) {
    if (ph < 5.5) return 'Acidic Soil';
    if (ph > 7.5) return 'Alkaline Soil';
    return 'Neutral/Loam';
  }
}
