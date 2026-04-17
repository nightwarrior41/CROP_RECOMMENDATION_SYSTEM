import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_model.dart';
import '../models/models.dart';

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

  List<WeatherAlert> generateSmartAlerts(WeatherModel weather) {
    final List<WeatherAlert> alerts = [];

    // 1. Storm / Rain check
    final condition = weather.description.toLowerCase();
    if (condition.contains('storm') || condition.contains('thunderstorm')) {
      alerts.add(const WeatherAlert(
        title: 'Severe Storm Warning',
        description: 'Thunderstorms and potential high winds detected. Secure loose farm equipment and delay field operations.',
        severity: AlertSeverity.critical,
        time: 'Immediate',
        icon: '⛈️',
        isActive: true,
      ));
    } else if (condition.contains('rain') || condition.contains('drizzle') || condition.contains('shower')) {
      alerts.add(const WeatherAlert(
        title: 'Rainfall Advisory',
        description: 'Precipitation expected. Avoid scheduled irrigation and check drainage channels for waterlogging risk.',
        severity: AlertSeverity.medium,
        time: 'Active',
        icon: '🌧️',
        isActive: true,
      ));
    }

    // 2. Heat check
    if (weather.temperature > 37) {
      alerts.add(const WeatherAlert(
        title: 'Extreme Heatwave',
        description: 'Temperatures reaching dangerous levels. Increase irrigation frequency and avoid midday manual labor.',
        severity: AlertSeverity.critical,
        time: 'During Daylight',
        icon: '🔥',
        isActive: true,
      ));
    } else if (weather.temperature > 32) {
      alerts.add(const WeatherAlert(
        title: 'High Temperature Advisory',
        description: 'Warm conditions may cause heat stress in sensitive crops. Monitor soil moisture closely.',
        severity: AlertSeverity.medium,
        time: 'Afternoon',
        icon: '🌡️',
        isActive: true,
      ));
    }

    // 3. Frost check
    if (weather.temperature < 3) {
      alerts.add(const WeatherAlert(
        title: 'Critical Frost Risk',
        description: 'Near-freezing temperatures detected. Immediate action required to cover sensitive crops or use heaters.',
        severity: AlertSeverity.critical,
        time: 'Tonight / Early Morning',
        icon: '❄️',
        isActive: true,
      ));
    } else if (weather.temperature < 8) {
      alerts.add(const WeatherAlert(
        title: 'Chilly Conditions',
        description: 'Low temperatures may slow down germination. Avoid nitrogen applications during this cold spell.',
        severity: AlertSeverity.medium,
        time: 'Nighttime',
        icon: '🌨️',
        isActive: true,
      ));
    }

    // 4. Wind check
    if (weather.windSpeed > 15) {
      alerts.add(const WeatherAlert(
        title: 'High Wind Warning',
        description: 'Wind speeds exceeding 15m/s. High risk of mechanical damage to tall crops and greenhouses.',
        severity: AlertSeverity.high,
        time: 'Active',
        icon: '💨',
        isActive: true,
      ));
    } else if (weather.windSpeed > 8) {
      alerts.add(const WeatherAlert(
        title: 'Breezy Conditions',
        description: 'Moderately high winds. Spraying pesticides or fertilizers is not recommended due to drift risk.',
        severity: AlertSeverity.low,
        time: 'Now',
        icon: '🌬️',
        isActive: true,
      ));
    }

    // 5. Humidity check (Disease risk)
    if (weather.humidity > 85 && weather.temperature > 20) {
      alerts.add(const WeatherAlert(
        title: 'Fungal Disease Risk',
        description: 'Warm and humid conditions are ideal for fungal growth (e.g., blight, mildew). Scout fields actively.',
        severity: AlertSeverity.high,
        time: 'Next 24 Hours',
        icon: '🐛',
        isActive: true,
      ));
    }

    // Default if no alerts generated - keep some information
    if (alerts.isEmpty) {
      alerts.add(const WeatherAlert(
        title: 'Stable Weather Conditions',
        description: 'No immediate weather threats detected for your agricultural operations.',
        severity: AlertSeverity.low,
        time: 'Current',
        icon: '✅',
        isActive: true,
      ));
    }

    return alerts;
  }
}

