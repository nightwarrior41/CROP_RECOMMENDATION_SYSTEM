import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/agro_service.dart';
import '../models/models.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import 'package:geolocator/geolocator.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with TickerProviderStateMixin {
  List<WeatherAlert> _alerts = [];
  bool _loading = true;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final locationService = LocationService();
    final weatherService = WeatherService();
    
    try {
      final Position pos = await locationService.getCurrentLocation();
      final weather = await weatherService.fetchWeather(pos.latitude, pos.longitude);
      final alerts = weatherService.generateSmartAlerts(weather);
      
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _loading = false;
        });
      }
    } catch (e) {
      // Fallback to mock data if API fails
      final alerts = await AgroService.fetchSmartAlerts(30.7, 76.7);
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using predicted alerts (Live API error: $e)'),
            backgroundColor: AppTheme.accentWarm,
          ),
        );
      }
    }
  }

  Color _severityColor(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.critical:
        return AppTheme.accentRed;
      case AlertSeverity.high:
        return const Color(0xFFE8724A);
      case AlertSeverity.medium:
        return AppTheme.accentWarm;
      case AlertSeverity.low:
        return AppTheme.accentCool;
    }
  }

  String _severityLabel(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.critical:
        return 'CRITICAL';
      case AlertSeverity.high:
        return 'HIGH';
      case AlertSeverity.medium:
        return 'MEDIUM';
      case AlertSeverity.low:
        return 'LOW';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAlerts = _alerts.where((a) => a.isActive).toList();
    final upcoming = _alerts.where((a) => !a.isActive).toList();

    return GradientBackground(
      child: SafeArea(
        child: _loading
            ? const LoadingOverlay(message: 'Fetching weather alerts...')
            : Column(
                children: [
                  _buildHeader(activeAlerts.length),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (activeAlerts.isNotEmpty) ...[
                            _buildActiveSection(activeAlerts),
                            const SizedBox(height: 24),
                          ],
                          _buildForecastGrid(),
                          const SizedBox(height: 24),
                          if (upcoming.isNotEmpty)
                            _buildUpcomingSection(upcoming),
                          const SizedBox(height: 20),
                          _buildSmartTips(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(int activeCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Alerts',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Real-time weather intelligence for your farm',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          if (activeCount > 0)
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, child) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed
                      .withValues(alpha: 0.1 + 0.1 * _pulseCtrl.value),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentRed
                        .withValues(alpha: 0.3 + 0.2 * _pulseCtrl.value),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: AppTheme.accentRed),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '$activeCount Active',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveSection(List<WeatherAlert> alerts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Alerts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...alerts.map((alert) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildActiveAlertCard(alert),
            )),
      ],
    );
  }

  Widget _buildActiveAlertCard(WeatherAlert alert) {
    final color = _severityColor(alert.severity);
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, child) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.15 + 0.05 * _pulseCtrl.value),
              AppTheme.card,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.4 + 0.15 * _pulseCtrl.value),
            width: 1.5,
          ),
        ),
        child: child,
      ),
      child: _alertCardContent(alert),
    );
  }

  Widget _alertCardContent(WeatherAlert alert) {
    final color = _severityColor(alert.severity);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(alert.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _severityLabel(alert.severity),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        alert.time,
                        style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          alert.description,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                  'View Details', Icons.info_outline_rounded, color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child:
                  _actionButton('Set Reminder', Icons.alarm_add_rounded, color),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastGrid() {
    final forecasts = [
      {'day': 'Today', 'icon': '⛅', 'high': '27°', 'low': '18°', 'rain': '20%'},
      {'day': 'Thu', 'icon': '🌧️', 'high': '22°', 'low': '16°', 'rain': '85%'},
      {'day': 'Fri', 'icon': '⛈️', 'high': '19°', 'low': '13°', 'rain': '92%'},
      {'day': 'Sat', 'icon': '🌤️', 'high': '24°', 'low': '15°', 'rain': '15%'},
      {'day': 'Sun', 'icon': '☀️', 'high': '28°', 'low': '17°', 'rain': '5%'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: '5-Day Forecast',
          subtitle: 'Agricultural impact assessment',
        ),
        const SizedBox(height: 12),
        Row(
          children: forecasts.map((f) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border, width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(
                        f['day']!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(f['icon']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 6),
                      Text(
                        f['high']!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        f['low']!,
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        f['rain']!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.accentCool,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUpcomingSection(List<WeatherAlert> alerts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Upcoming Advisories',
          subtitle: 'Plan ahead for your crops',
        ),
        const SizedBox(height: 12),
        ...alerts.asMap().entries.map((e) {
          final i = e.key;
          final alert = e.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + i * 100),
            curve: Curves.easeOutCubic,
            builder: (_, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(
                  offset: Offset(0, 10 * (1 - v)), child: child),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildUpcomingCard(alert),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUpcomingCard(WeatherAlert alert) {
    final color = _severityColor(alert.severity);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(alert.icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.time,
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Text(
              _severityLabel(alert.severity),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartTips() {
    final tips = [
      {
        'icon': '💡',
        'tip':
            'Heavy rain forecast — prepare drainage channels before Thursday.'
      },
      {
        'icon': '🔧',
        'tip': 'Storm tonight — secure greenhouse covers and tighten netting.'
      },
      {
        'icon': '📱',
        'tip':
            'Enable push notifications for real-time critical weather updates.'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Smart Farm Tips',
          subtitle: 'AI-generated based on forecast',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border, width: 1),
          ),
          child: Column(
            children: tips.asMap().entries.map((e) {
              final i = e.key;
              final tip = e.value;
              return Padding(
                padding: EdgeInsets.only(bottom: i < tips.length - 1 ? 14 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(tip['icon']!,
                            style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip['tip']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
