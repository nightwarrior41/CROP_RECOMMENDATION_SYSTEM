import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agro_intelligence/screens/home_screen.dart';
import 'package:agro_intelligence/screens/crop_prediction_screen.dart';
import 'package:agro_intelligence/screens/profit_analysis_screen.dart';
import 'package:agro_intelligence/screens/best_crop_screen.dart';
import 'package:agro_intelligence/screens/alerts_screen.dart';
import 'package:agro_intelligence/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AgroIntelligenceApp());
}

class AgroIntelligenceApp extends StatelessWidget {
  const AgroIntelligenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroMind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CropPredictionScreen(),
    const ProfitAnalysisScreen(),
    const BestCropScreen(),
    const AlertsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      _fadeController.reset();
      setState(() => _currentIndex = index);
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    final items = [
      {'icon': Icons.dashboard_rounded, 'label': 'Home'},
      {'icon': Icons.grain_rounded, 'label': 'Predict'},
      {'icon': Icons.trending_up_rounded, 'label': 'Profit'},
      {'icon': Icons.auto_awesome_rounded, 'label': 'Best Crop'},
      {'icon': Icons.notifications_active_rounded, 'label': 'Alerts'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.navBg,
        border: Border(
          top: BorderSide(color: AppTheme.accent.withValues(alpha: 0.15), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isSelected = i == _currentIndex;
              return GestureDetector(
                onTap: () => _onTabTapped(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accent.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i]['icon'] as IconData,
                        color: isSelected ? AppTheme.accent : AppTheme.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected ? AppTheme.accent : AppTheme.textMuted,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
