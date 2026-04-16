import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/agro_service.dart';
import '../models/models.dart';

class BestCropScreen extends StatefulWidget {
  const BestCropScreen({super.key});

  @override
  State<BestCropScreen> createState() => _BestCropScreenState();
}

class _BestCropScreenState extends State<BestCropScreen>
    with TickerProviderStateMixin {
  List<BestCropRecommendation> _recommendations = [];
  List<HistoricalWeather> _historicalData = [];
  bool _loading = true;
  int _selectedRec = 0;
  late AnimationController _cardCtrl;
  late AnimationController _radarCtrl;
  late Animation<double> _radarAnim;

  final double _lat = 30.7333;
  final double _lon = 76.7794;

  @override
  void initState() {
    super.initState();
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _radarCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _radarAnim = CurvedAnimation(
        parent: _radarCtrl, curve: Curves.easeOutCubic);
    _loadData();
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    _radarCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final recs =
        await AgroService.getBestCropRecommendations(_lat, _lon);
    final hist = await AgroService.fetchHistoricalWeather(_lat, _lon);
    if (mounted) {
      setState(() {
        _recommendations = recs;
        _historicalData = hist;
        _loading = false;
      });
      _cardCtrl.forward();
      _radarCtrl.forward();
    }
  }

  void _selectRec(int i) {
    setState(() => _selectedRec = i);
    _radarCtrl.reset();
    _radarCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: _loading
            ? const LoadingOverlay(
                message: 'Analyzing 10+ years of weather data...')
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAnalysisInfo(),
                          const SizedBox(height: 20),
                          _buildHistoricalChart(),
                          const SizedBox(height: 24),
                          _buildTopPickLabel(),
                          const SizedBox(height: 14),
                          _buildRecommendationCards(),
                          const SizedBox(height: 24),
                          if (_recommendations.isNotEmpty)
                            _buildDetailPanel(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best Crop for You',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'ML trained on 12 years of local weather data',
                  style:
                      TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('⭐', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisInfo() {
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
            child: _infoChip(
                '📅', '${_historicalData.length} Years', 'Data Range'),
          ),
          Container(width: 1, height: 40, color: AppTheme.border),
          Expanded(
              child: _infoChip('🌡️', '24.8°C', 'Avg Temp')),
          Container(width: 1, height: 40, color: AppTheme.border),
          Expanded(
              child: _infoChip('🌧️', '1020mm', 'Avg Rain')),
        ],
      ),
    );
  }

  Widget _infoChip(String icon, String value, String label) {
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
            style:
                const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildHistoricalChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Historical Rainfall Pattern',
          subtitle: '12-year analysis used for ML training',
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
                height: 80,
                child: MiniBarChart(
                  values: _historicalData
                      .map((h) => h.totalRainfall)
                      .toList(),
                  labels: _historicalData
                      .map((h) => h.year.toString().substring(2))
                      .toList(),
                  color: AppTheme.accentCool,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _legendDot(AppTheme.accentCool, 'Rainfall (mm)'),
                  const SizedBox(width: 16),
                  _legendDot(AppTheme.accentWarm, 'Temperature °C'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildTopPickLabel() {
    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
      children: _recommendations.asMap().entries.map((e) {
        final i = e.key;
        final rec = e.value;
        final isSelected = i == _selectedRec;
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
              onTap: () => _selectRec(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.08)
                      : AppTheme.card,
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
                        Text(rec.emoji,
                            style: const TextStyle(fontSize: 34)),
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
                          ConfidenceBar(
                              value: rec.score / 100, color: color),
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
                                fontSize: 10,
                                color: AppTheme.textMuted)),
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
    final rec = _recommendations[_selectedRec];
    final colors = [AppTheme.accent, AppTheme.accentWarm, AppTheme.accentCool];
    final color = colors[_selectedRec % colors.length];

    return FadeTransition(
      opacity: _radarAnim,
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
                // Radar chart
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
                // Score breakdown
                _scoreRow('🌡️', 'Climate Match',
                    rec.climateMatch, AppTheme.accentCool),
                const SizedBox(height: 10),
                _scoreRow('🪨', 'Soil Match',
                    rec.soilMatch, AppTheme.accentWarm),
                const SizedBox(height: 10),
                _scoreRow('💰', 'Profitability',
                    rec.profitability, AppTheme.accent),
                const SizedBox(height: 10),
                _scoreRow('💧', 'Water Efficiency',
                    rec.waterEfficiency, AppTheme.accentCool),
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
                    Expanded(child: _proConList('✅ Pros', rec.pros, AppTheme.accent)),
                    const SizedBox(width: 12),
                    Expanded(child: _proConList('⚠️ Cons', rec.cons, AppTheme.accentWarm)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(
      String icon, String label, double value, Color color) {
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
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  item,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      height: 1.4),
                ),
              )),
        ],
      ),
    );
  }
}
