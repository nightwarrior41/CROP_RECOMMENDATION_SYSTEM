class WeatherModel {
  final String cityName;
  final double temperature;
  final String description;
  final String iconCode;
  final double feelsLike;
  final int humidity;
  final double windSpeed;

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.iconCode,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'] ?? 'Unknown',
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      iconCode: json['weather'][0]['icon'] ?? '',
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';
}
