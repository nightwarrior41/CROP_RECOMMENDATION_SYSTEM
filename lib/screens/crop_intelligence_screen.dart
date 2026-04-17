import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/agro_service.dart';
import '../models/models.dart';
import '../services/crop_prediction_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CropIntelligenceScreen extends StatefulWidget {
  final int initialTab;
  const CropIntelligenceScreen({super.key, this.initialTab = 0});

  @override
  State<CropIntelligenceScreen> createState() => _CropIntelligenceScreenState();
}

class _CropIntelligenceScreenState extends State<CropIntelligenceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // --- Common Data ---
  double _lat = 30.7333;
  double _lon = 76.7794;
  String _locationName = 'Punjab, India';
  Map<String, dynamic>? _weatherAnalysis;
  bool _isDataLoaded = false;

  // --- Prediction Tab Data ---
  List<CropPrediction> _predictions = [];
  bool _predictLoading = false;
  bool _predictHasResult = false;
  String _selectedLandType = 'Loam';
  final List<String> _landTypes = [
    'Loam', 'Clay', 'Sandy', 'Silt', 'Black', 'Alluvial', 'Red'
  ];
  late AnimationController _predictListCtrl;

  // --- Best Crop Tab Data ---
  List<BestCropRecommendation> _recs = [];
  List<HistoricalWeather> _historicalData = [];
  bool _recsLoading = true;
  int _selectedRecIdx = 0;
  late AnimationController _recsCardCtrl;
  late AnimationController _recsRadarCtrl;
  late Animation<double> _recsRadarAnim;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTab);

    // Prediction Anims
    _predictListCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    // Best Crop Anims
    _recsCardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _recsRadarCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _recsRadarAnim =
        CurvedAnimation(parent: _recsRadarCtrl, curve: Curves.easeOutCubic);

    _initIntelligenceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _predictListCtrl.dispose();
    _recsCardCtrl.dispose();
    _recsRadarCtrl.dispose();
    super.dispose();
  }

  // --- Prediction Logic ---
  Future<void> _runQuickPrediction() async {
    if (!_isDataLoaded || _weatherAnalysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for location and weather data to sync...')),
      );
      return;
    }

    setState(() {
      _predictLoading = true;
      _predictHasResult = false;
    });

    try {
      final results = await CropPredictionService.predictCrop(
        temperature: (_weatherAnalysis!['avg_temp'] as num).toDouble(),
        humidity: (_weatherAnalysis!['avg_humidity'] as num).toDouble(),
        rainfall: (_weatherAnalysis!['total_rainfall'] as num).toDouble(),
      );
      if (mounted) {
        setState(() {
          _predictions = results;
          _predictLoading = false;
          _predictHasResult = true;
        });
        _predictListCtrl.reset();
        _predictListCtrl.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _predictLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get predictions: \$e')),
        );
      }
    }
  }

  // --- Best Crop Logic ---
  // --- Data & Location Initialization ---
  Future<void> _initIntelligenceData() async {
    final locationService = LocationService();
    Position? pos;
    String? localPlace;

    try {
      pos = await locationService.getCurrentLocation();
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        localPlace = '${p.locality}, ${p.administrativeArea}';
      }
    } catch (e) {
      debugPrint('Location error: \$e');
    }

    final lat = pos?.latitude ?? _lat;
    final lon = pos?.longitude ?? _lon;

    try {
      final analysis = await CropPredictionService.fetchWeatherAnalysis(lat, lon);
      if (mounted) {
        setState(() {
          _lat = lat;
          _lon = lon;
          _locationName = localPlace ?? 'Unknown Location';
          _weatherAnalysis = analysis;
          _isDataLoaded = true;
          _recsLoading = false;
        });
        _recsCardCtrl.forward();
        _recsRadarCtrl.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _recsLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync Error: \$e')),
        );
      }
    }
  }

  void _selectRecommendation(int i) {
    setState(() => _selectedRecIdx = i);
    _recsRadarCtrl.reset();
    _recsRadarCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPredictionTab(),
                  _buildBestCropTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crop Intelligence',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'AI-powered agricultural analysis',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🧠', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppTheme.accent,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(text: 'Quick Predict'),
          Tab(text: 'Deep Analysis'),
        ],
      ),
    );
  }

  // --- SHARED WIDGETS ---
  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.accentCool.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.accentCool.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.gps_fixed_rounded,
                color: AppTheme.accentCool, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                          color: AppTheme.accent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'GPS Location Active',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _locationName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${_lat.toStringAsFixed(4)}°N, ${_lon.toStringAsFixed(4)}°E',
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: PREDICTION ---
  Widget _buildPredictionTab() {
    return _predictLoading
        ? const LoadingOverlay(message: 'Running ML prediction model...')
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationCard(),
                const SizedBox(height: 20),
                _buildLandTypeSelector(),
                const SizedBox(height: 20),
                _buildPredictButton(),
                if (_predictHasResult) ...[
                  const SizedBox(height: 24),
                  _buildPredictResultHeader(),
                  const SizedBox(height: 14),
                  ..._buildPredictionCards(),
                ],
              ],
            ),
          );
  }

  Widget _buildLandTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Land Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _landTypes.map((type) {
            final selected = type == _selectedLandType;
            return GestureDetector(
              onTap: () => setState(() => _selectedLandType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.accent.withValues(alpha: 0.15)
                      : AppTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppTheme.accent : AppTheme.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppTheme.accent : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPredictButton() {
    return GestureDetector(
      onTap: _runQuickPrediction,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4FA82E), AppTheme.accent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Run ML Prediction',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictResultHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ML Results',
                style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Based on current weather data',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${_predictions.length} crops suitable for your land',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPredictionCards() {
    return List.generate(_predictions.length, (i) {
      final crop = _predictions[i];
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 400 + (i * 80)),
        curve: Curves.easeOutCubic,
        builder: (_, v, child) => Transform.translate(
          offset: Offset(0, 20 * (1 - v)),
          child: Opacity(opacity: v, child: child),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _PredictionCard(crop: crop, rank: i + 1),
        ),
      );
    });
  }

  // --- TAB 2: DEEP ANALYSIS (METEOSTAT) ---
  Widget _buildBestCropTab() {
    if (!_isDataLoaded || _weatherAnalysis == null) {
      return const LoadingOverlay(message: 'Connecting to Meteostat services...');
    }

    final history = _weatherAnalysis!['history'] as List;
    final List<double> rainValues = history.map((h) => (h['rainfall'] as num).toDouble()).toList();
    final List<String> rainLabels = history.map((h) => h['date'] as String).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisInfo(),
          const SizedBox(height: 20),
          _buildHistoricalChart(rainValues, rainLabels),
          const SizedBox(height: 24),
          _buildDataInsightCard(),
        ],
      ),
    );
  }

  Widget _buildAnalysisInfo() {
    final avgTemp = _weatherAnalysis?['avg_temp'] ?? 0.0;
    final totalRain = _weatherAnalysis?['total_rainfall'] ?? 0.0;
    final avgHum = _weatherAnalysis?['avg_humidity'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentPurple.withValues(alpha: 0.12),
            AppTheme.card,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.accentPurple.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _recsInfoChip('📅', 'Past 90 Days', 'Data Period'),
          ),
          Container(width: 1, height: 40, color: AppTheme.border),
          Expanded(child: _recsInfoChip('🌡️', '\$avgTemp°C', 'Avg Temp')),
          Container(width: 1, height: 40, color: AppTheme.border),
          Expanded(child: _recsInfoChip('🌧️', '\${totalRain}mm', 'Total Rain')),
        ],
      ),
    );
  }

  Widget _recsInfoChip(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildHistoricalChart(List<double> values, List<String> labels) {
    if (values.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Meteostat Historical Rainfall',
          subtitle: 'Daily precipitation patterns (Last 3 Months)',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border, width: 1),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 100,
                child: MiniBarChart(
                  values: values,
                  labels: labels,
                  color: AppTheme.accentCool,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _legendDot(AppTheme.accentCool, 'Rainfall (mm)'),
                  const SizedBox(width: 16),
                  const Text(
                    'Data sourced from local weather stations via Meteostat',
                    style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataInsightCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentCool.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentCool.withValues(alpha: 0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: AppTheme.accentCool, size: 20),
              SizedBox(width: 10),
              Text(
                'Climate Insights',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'The historical weather pattern from the last 90 days is used to generate stable averages for the ML prediction model, ensuring that recommendations are based on recent regional trends.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPickLabel() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.accentPurple.withValues(alpha: 0.2),
                AppTheme.accent.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppTheme.accentPurple.withValues(alpha: 0.4), width: 1),
          ),
          child: const Text(
            '🤖 ML Recommendation',
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.accentPurple,
                fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCards() {
    return Column(
      children: _recs.asMap().entries.map((e) {
        final i = e.key;
        final rec = e.value;
        final isSelected = i == _selectedRecIdx;
        final colors = [
          AppTheme.accent,
          AppTheme.accentWarm,
          AppTheme.accentCool
        ];
        final color = colors[i % colors.length];

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + i * 120),
          curve: Curves.easeOutCubic,
          builder: (_, v, child) => Transform.translate(
            offset: Offset(30 * (1 - v), 0),
            child: Opacity(opacity: v, child: child),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => _selectRecommendation(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color:
                      isSelected ? color.withValues(alpha: 0.08) : AppTheme.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.5)
                        : AppTheme.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Text(rec.emoji, style: const TextStyle(fontSize: 34)),
                        if (i == 0)
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('★',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.white)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec.cropName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ConfidenceBar(value: rec.score / 100, color: color),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${rec.score.toInt()}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: color,
                            letterSpacing: -1,
                          ),
                        ),
                        const Text('score',
                            style: TextStyle(
                                fontSize: 10, color: AppTheme.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailPanel() {
    final rec = _recs[_selectedRecIdx];
    final colors = [AppTheme.accent, AppTheme.accentWarm, AppTheme.accentCool];
    final color = colors[_selectedRecIdx % colors.length];

    return FadeTransition(
      opacity: _recsRadarAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: '${rec.emoji} ${rec.cropName} Deep Analysis',
            subtitle: 'ML-scored across 4 dimensions',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: RadarChart(
                      values: [
                        rec.climateMatch,
                        rec.soilMatch,
                        rec.profitability,
                        rec.waterEfficiency,
                      ],
                      labels: ['Climate', 'Soil', 'Profit', 'Water'],
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _scoreRow(
                    '🌡️', 'Climate Match', rec.climateMatch, AppTheme.accentCool),
                const SizedBox(height: 10),
                _scoreRow(
                    '🪨', 'Soil Match', rec.soilMatch, AppTheme.accentWarm),
                const SizedBox(height: 10),
                _scoreRow('💰', 'Profitability', rec.profitability, AppTheme.accent),
                const SizedBox(height: 10),
                _scoreRow(
                    '💧', 'Water Efficiency', rec.waterEfficiency, AppTheme.accentCool),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Why this crop?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rec.reasoning,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _proConList('✅ Pros', rec.pros, AppTheme.accent)),
                    const SizedBox(width: 12),
                    Expanded(
                        child:
                            _proConList('⚠️ Cons', rec.cons, AppTheme.accentWarm)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(String icon, String label, double value, Color color) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: ConfidenceBar(value: value, color: color, height: 5),
        ),
        const SizedBox(width: 8),
        Text(
          '${(value * 100).toInt()}%',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }

  Widget _proConList(String title, List<String> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  item,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                ),
              )),
        ],
      ),
    );
  }
}

// --- Local Widget Class from Prediction Screen ---
class _PredictionCard extends StatefulWidget {
  final CropPrediction crop;
  final int rank;

  const _PredictionCard({required this.crop, required this.rank});

  @override
  State<_PredictionCard> createState() => _PredictionCardState();
}

class _PredictionCardState extends State<_PredictionCard> {
  bool _expanded = false;

  Color get _rankColor {
    switch (widget.rank) {
      case 1:
        return AppTheme.accent;
      case 2:
        return AppTheme.accentWarm;
      case 3:
        return AppTheme.accentCool;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final crop = widget.crop;
    final pct = (crop.confidence * 100).toInt();

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: _rankColor.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(crop.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            crop.cropName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _rankColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${widget.rank}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _rankColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        crop.season,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$pct%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _rankColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Text(
                      'confidence',
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConfidenceBar(value: crop.confidence, color: _rankColor),
            const SizedBox(height: 12),
            Row(
              children: [
                _infoChip('🌾', '${crop.expectedYield}t/ha'),
                const SizedBox(width: 8),
                _infoChip('🪨', crop.soilType),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0),
              secondChild: _buildExpanded(crop),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textMuted,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildExpanded(CropPrediction crop) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),
          const Text(
            'Requirements',
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          ...crop.requirements.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _rankColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      r,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
