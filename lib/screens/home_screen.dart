import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/agro_service.dart';
import '../services/crop_prediction_service.dart';
import '../models/models.dart';
import 'weather_screen.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';


class HomeScreen extends StatefulWidget {
  final Function(int, {int? subTab})? onNavigate;
  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  WeatherData? _weather;
  List<WeatherAlert> _activeAlerts = [];
  CropPrediction? _recommendedCrop;
  Position? _currentPosition;
  String? _locality;
  WeatherModel? _realWeather;
  bool _loading = true;
  late AnimationController _headerCtrl;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
    _loadData();
  }

  Future<void> _loadData() async {
    final locationService = LocationService();
    Position? pos;
    String? localPlace;
    try {
      pos = await locationService.getCurrentLocation();
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        localPlace = '${p.locality}, ${p.administrativeArea}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Location error: $e'),
              backgroundColor: AppTheme.accentRed),
        );
      }
    }

    final lat = pos?.latitude ?? 30.7;
    final lon = pos?.longitude ?? 76.7;

    final weatherService = WeatherService();
    WeatherModel? realWeather;
    try {
      realWeather = await weatherService.fetchWeather(lat, lon);
    } catch (e) {
      // Sliently fail for real weather on home, UI will handle null
    }

    final weather = await AgroService.fetchCurrentWeather(lat, lon);
    final alerts = await AgroService.fetchSmartAlerts(lat, lon);
    CropPrediction? pred;
    try {
      pred = await CropPredictionService.predictCrop(
        temperature: weather.temperature,
        humidity: weather.humidity.toDouble(),
        ph: 6.5,
        rainfall: weather.rainfall.toDouble(),
      );
    } catch (e) {
      // Handle error implicitly by leaving pred as null
    }

    if (mounted) {
      setState(() {
        _currentPosition = pos;
        _locality = localPlace;
        _weather = weather;
        _realWeather = realWeather;
        _activeAlerts = alerts.where((a) => a.isActive).toList();
        _recommendedCrop = pred;
        _loading = false;
      });
      _headerCtrl.forward();
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: _loading
            ? const LoadingOverlay(message: 'Loading your farm data...')
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildWeatherCard(),
          if (_recommendedCrop != null) _buildWeatherBasedRecommendation(),
          if (_activeAlerts.isNotEmpty) _buildAlertBanner(),
          _buildQuickActions(),
          _buildSeasonInfo(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SlideTransition(
      position: _headerSlide,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AgroMind',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Good Morning,\nFarmer',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      height: 1.15,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.4), width: 2),
              ),
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.card,
                child: Text('👨‍🌾', style: TextStyle(fontSize: 22)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final w = _weather!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.accentCool.withValues(alpha: 0.18),
              AppTheme.accent.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.accentCool.withValues(alpha: 0.25), width: 1),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(w.icon, style: const TextStyle(fontSize: 44)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_realWeather != null) ...[
                        Row(
                          children: [
                            Image.network(_realWeather!.iconUrl, width: 32, height: 32),
                            const SizedBox(width: 8),
                            Text(
                              '${_realWeather!.temperature.toStringAsFixed(1)}°C',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _realWeather!.description.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ] else ...[
                        Text(
                          '${w.temperature.toStringAsFixed(1)}°C',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          w.condition,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 12, color: AppTheme.accentCool),
                          const SizedBox(width: 3),
                          Text(
                            _locality ?? w.location,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textMuted),
                          ),
                          if (_currentPosition != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(${_currentPosition!.latitude.toStringAsFixed(2)}, ${_currentPosition!.longitude.toStringAsFixed(2)})',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.accentCool
                                      .withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _weatherDetail('💧', '${w.humidity.toInt()}%', 'Humidity'),
                _weatherDetail('🌧️', '${w.rainfall}mm', 'Rainfall'),
                _weatherDetail('💨', '${w.windSpeed}km/h', 'Wind'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WeatherScreen()),
                  );
                },
                icon: const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.accentCool),
                label: const Text(
                  'VIEW DETAILED WEATHER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppTheme.accentCool,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.accentCool.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );

  }

  Widget _weatherDetail(String icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildWeatherBasedRecommendation() {
    final rec = _recommendedCrop!;
    final pct = (rec.confidence * 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.accent.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.accent, size: 16),
                SizedBox(width: 8),
                Text(
                  'Recommended for current weather',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(rec.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.cropName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ConfidenceBar(
                                value: rec.confidence,
                                color: AppTheme.accent,
                                height: 6),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$pct%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.accent,
                                ),
                              ),
                              Text('Success Rate',
                                  style: TextStyle(
                                      fontSize: 9, color: AppTheme.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner() {
    return GestureDetector(
      onTap: () => widget.onNavigate?.call(3),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.accentRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppTheme.accentRed.withValues(alpha: 0.35), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppTheme.accentRed),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_activeAlerts.length} active alert${_activeAlerts.length > 1 ? 's' : ''}: ${_activeAlerts.first.title}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.accentRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.accentRed, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': '🌱',
        'label': 'Predict\nCrops',
        'color': AppTheme.accent,
        'tab': 1,
        'subTab': 0
      },
      {
        'icon': '💰',
        'label': 'Profit\nAnalysis',
        'color': AppTheme.accentWarm,
        'tab': 2,
      },
      {
        'icon': '⭐',
        'label': 'Best\nCrop',
        'color': AppTheme.accentPurple,
        'tab': 1,
        'subTab': 1
      },
      {
        'icon': '🔔',
        'label': 'Smart\nAlerts',
        'color': AppTheme.accentCool,
        'tab': 3,
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Quick Access',
            subtitle: 'AI-powered tools for your farm',
          ),
          const SizedBox(height: 14),
          Row(
            children: actions.map((a) {
              final color = a['color'] as Color;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => widget.onNavigate
                        ?.call(a['tab'] as int, subTab: a['subTab'] as int?),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: color.withValues(alpha: 0.2), width: 1),
                      ),
                      child: Column(
                        children: [
                          Text(a['icon'] as String,
                              style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 8),
                          Text(
                            a['label'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Growing Season Status',
            subtitle: 'Current agricultural calendar',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.15), width: 1),
            ),
            child: Column(
              children: [
                _seasonRow('🌱', 'Wheat Planting', 'Oct 15 – Nov 30', 0.65,
                    AppTheme.accent),
                const SizedBox(height: 14),
                _seasonRow('💧', 'Irrigation Cycle', 'Every 12–15 days', 0.4,
                    AppTheme.accentCool),
                const SizedBox(height: 14),
                _seasonRow('🌾', 'Harvest Window', 'Mar 20 – Apr 10', 0.15,
                    AppTheme.accentWarm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _seasonRow(
      String icon, String label, String detail, double progress, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ),
            Text(detail,
                style:
                    const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
        const SizedBox(height: 6),
        ConfidenceBar(value: progress, color: color, height: 5),
      ],
    );
  }
}
