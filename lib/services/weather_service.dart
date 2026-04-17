import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<WeatherModel> fetchWeather(double lat, double lon) async {
    final apiKey = dotenv.env['WEATHER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Weather API Key not found in .env file');
    }

    final url = Uri.parse('$_baseUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return WeatherModel.fromJson(data);
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to load weather data';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error: Please check your internet connection.');
      }
      rethrow;
    }
  }
}
