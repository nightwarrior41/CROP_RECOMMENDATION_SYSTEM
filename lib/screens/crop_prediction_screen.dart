import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/crop_prediction_service.dart';
import '../models/models.dart';

class CropPredictionScreen extends StatefulWidget {
  const CropPredictionScreen({super.key});

  @override
  State<CropPredictionScreen> createState() => _CropPredictionScreenState();
}

class _CropPredictionScreenState extends State<CropPredictionScreen>
    with TickerProviderStateMixin {
  
  final TextEditingController _tempCtrl = TextEditingController();
  final TextEditingController _humCtrl = TextEditingController();
  final TextEditingController _phCtrl = TextEditingController();
  final TextEditingController _rainCtrl = TextEditingController();

  CropPrediction? _prediction;
  bool _loading = false;
  bool _hasResult = false;
  late AnimationController _listCtrl;

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _tempCtrl.dispose();
    _humCtrl.dispose();
    _phCtrl.dispose();
    _rainCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _runPrediction() async {
    // Validate inputs
    if (_tempCtrl.text.isEmpty || _humCtrl.text.isEmpty || 
        _phCtrl.text.isEmpty || _rainCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all environmental inputs')),
      );
      return;
    }

    final double? temp = double.tryParse(_tempCtrl.text);
    final double? hum = double.tryParse(_humCtrl.text);
    final double? ph = double.tryParse(_phCtrl.text);
    final double? rain = double.tryParse(_rainCtrl.text);

    if (temp == null || hum == null || ph == null || rain == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numerical values')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _hasResult = false;
    });

    try {
      final result = await CropPredictionService.predictCrop(
        temperature: temp,
        humidity: hum,
        ph: ph,
        rainfall: rain,
      );
      
      if (mounted) {
        setState(() {
          _prediction = result;
          _loading = false;
          _hasResult = true;
        });
        _listCtrl.reset();
        _listCtrl.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _loading
                  ? const LoadingOverlay(
                      message: 'Running ML prediction model...')
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputForm(),
                          const SizedBox(height: 20),
                          _buildPredictButton(),
                          if (_hasResult && _prediction != null) ...[
                            const SizedBox(height: 24),
                            _buildResultHeader(),
                            const SizedBox(height: 14),
                            _buildPredictionCard(),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crop Prediction',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Enter environmental factors',
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.textMuted),
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
            child: const Text('🌱', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: 'Temperature (°C)',
          controller: _tempCtrl,
          icon: Icons.thermostat_rounded,
          hint: 'e.g. 25.5',
        ),
        const SizedBox(height: 12),
        _buildInputField(
          label: 'Humidity (%)',
          controller: _humCtrl,
          icon: Icons.water_drop_rounded,
          hint: 'e.g. 71.0',
        ),
        const SizedBox(height: 12),
        _buildInputField(
          label: 'Soil pH',
          controller: _phCtrl,
          icon: Icons.science_rounded,
          hint: 'e.g. 6.5',
        ),
        const SizedBox(height: 12),
        _buildInputField(
          label: 'Rainfall (mm)',
          controller: _rainCtrl,
          icon: Icons.cloud_rounded,
          hint: 'e.g. 100.0',
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentCool, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: label,
                labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                hintText: hint,
                hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.5), fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictButton() {
    return GestureDetector(
      onTap: _runPrediction,
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
            Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 20),
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

  Widget _buildResultHeader() {
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
              'Based on Random Forest model',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Best suitable crop for your condition',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - v)),
        child: Opacity(opacity: v, child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _PredictionCard(crop: _prediction!, rank: 1),
      ),
    );
  }
}

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
    return AppTheme.accent;
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
          border: Border.all(
              color: _rankColor.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(crop.emoji,
                    style: const TextStyle(fontSize: 32)),
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
                              '#\${widget.rank}',
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
                      '\$pct%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _rankColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Text(
                      'confidence',
                      style: TextStyle(
                          fontSize: 10, color: AppTheme.textMuted),
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
                _infoChip('🌾', '\${crop.expectedYield}t/ha'),
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
