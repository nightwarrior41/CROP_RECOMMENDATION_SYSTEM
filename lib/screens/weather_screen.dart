import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../models/weather_model.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  
  WeatherModel? _weather;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Position position = await _locationService.getCurrentLocation();
      final weather = await _weatherService.fetchWeather(
        position.latitude,
        position.longitude,
      );
      
      if (mounted) {
        setState(() {
          _weather = weather;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
        _showErrorSnackBar(_errorMessage!);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.accentRed,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _fetchWeatherData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Real-Time Weather'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchWeatherData,
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.accent),
                      SizedBox(height: 16),
                      Text('Fetching weather...', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : _errorMessage != null
                  ? _buildErrorView()
                  : _buildWeatherContent(),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.accentRed, size: 64),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchWeatherData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildWeatherContent() {
    if (_weather == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _weather!.cityName,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _weather!.description.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.accent,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Image.network(
            _weather!.iconUrl,
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.wb_sunny_rounded, size: 80, color: Colors.orange),
          ),
          Text(
            '${_weather!.temperature.toStringAsFixed(1)}°',
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
              height: 1,
            ),
          ),
          Text(
            'Feels like ${_weather!.feelsLike.toStringAsFixed(1)}°',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 48),
          _buildWeatherDetailsGrid(),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailsGrid() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _weatherDetailItem(
            icon: Icons.water_drop_rounded,
            value: '${_weather!.humidity}%',
            label: 'Humidity',
            color: Colors.blue,
          ),
          Container(height: 40, width: 1, color: AppTheme.textMuted.withValues(alpha: 0.2)),
          _weatherDetailItem(
            icon: Icons.air_rounded,
            value: '${_weather!.windSpeed} m/s',
            label: 'Wind Speed',
            color: Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _weatherDetailItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
