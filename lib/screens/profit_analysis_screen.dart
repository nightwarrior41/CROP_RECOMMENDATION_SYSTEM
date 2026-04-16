import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/agro_service.dart';
import '../models/models.dart';

class ProfitAnalysisScreen extends StatefulWidget {
  const ProfitAnalysisScreen({super.key});

  @override
  State<ProfitAnalysisScreen> createState() => _ProfitAnalysisScreenState();
}

class _ProfitAnalysisScreenState extends State<ProfitAnalysisScreen>
    with SingleTickerProviderStateMixin {
  List<CropProfit> _allCrops = [];
  CropProfit? _selectedCrop;
  bool _loading = true;
  String _searchQuery = '';
  late TextEditingController _searchCtrl;
  late AnimationController _detailCtrl;
  late Animation<double> _detailAnim;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Cereal', 'Vegetable', 'Spice'];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _detailCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _detailAnim = CurvedAnimation(
        parent: _detailCtrl, curve: Curves.easeOutCubic);
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final crops = await AgroService.fetchCropProfits();
    if (mounted) {
      setState(() {
        _allCrops = crops;
        _loading = false;
      });
    }
  }

  List<CropProfit> get _filteredCrops {
    return _allCrops.where((c) {
      final matchSearch = c.cropName
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      final matchCat =
          _selectedCategory == 'All' || c.category == _selectedCategory;
      return matchSearch && matchCat;
    }).toList()
      ..sort((a, b) => b.profitPerHectare.compareTo(a.profitPerHectare));
  }

  List<CropProfit> get _highProfitSuggestions {
    if (_selectedCrop == null) return [];
    return _allCrops
        .where((c) =>
            c.cropName != _selectedCrop!.cropName &&
            c.profitPerHectare > _selectedCrop!.profitPerHectare)
        .toList()
      ..sort((a, b) => b.profitPerHectare.compareTo(a.profitPerHectare));
  }

  void _selectCrop(CropProfit crop) {
    setState(() => _selectedCrop = crop);
    _detailCtrl.reset();
    _detailCtrl.forward();
    // Scroll to detail — handled via scroll controller in full impl
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: _loading
            ? const LoadingOverlay(message: 'Loading crop profit data...')
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
                          _buildSummaryStats(),
                          const SizedBox(height: 20),
                          _buildSearchBar(),
                          const SizedBox(height: 12),
                          _buildCategoryFilter(),
                          const SizedBox(height: 16),
                          _buildCropList(),
                          if (_selectedCrop != null) ...[
                            const SizedBox(height: 24),
                            _buildDetailPanel(),
                            const SizedBox(height: 20),
                            _buildSuggestions(),
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
                  'Profit Analysis',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Explore and compare crop profitability',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentWarm.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('💰', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    final totalCrops = _allCrops.length;
    final highest = _allCrops.isEmpty
        ? null
        : _allCrops.reduce((a, b) =>
            a.profitPerHectare > b.profitPerHectare ? a : b);
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Crops Tracked',
            value: '$totalCrops',
            icon: Icons.grain_rounded,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Top Earner',
            value: highest?.emoji ?? '-',
            icon: Icons.star_rounded,
            color: AppTheme.accentWarm,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(
            color: AppTheme.textPrimary, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Search crops...',
          hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded,
              color: AppTheme.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final selected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.accentWarm.withValues(alpha: 0.15)
                      : AppTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? AppTheme.accentWarm
                        : AppTheme.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppTheme.accentWarm
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCropList() {
    final crops = _filteredCrops;
    if (crops.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No crops found',
              style:
                  TextStyle(color: AppTheme.textMuted, fontSize: 14)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'All Crops',
          subtitle: '${crops.length} results',
        ),
        const SizedBox(height: 12),
        ...crops.asMap().entries.map((e) {
          final crop = e.value;
          final isSelected = _selectedCrop?.cropName == crop.cropName;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => _selectCrop(crop),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accentWarm.withValues(alpha: 0.08)
                      : AppTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.accentWarm.withValues(alpha: 0.5)
                        : AppTheme.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(crop.emoji,
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            crop.cropName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            crop.category,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${crop.profitPerHectare.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.accentWarm,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              crop.growthPercent >= 0
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              size: 13,
                              color: crop.growthPercent >= 0
                                  ? AppTheme.accent
                                  : AppTheme.accentRed,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${crop.growthPercent}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: crop.growthPercent >= 0
                                    ? AppTheme.accent
                                    : AppTheme.accentRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded,
                      color: isSelected
                          ? AppTheme.accentWarm
                          : AppTheme.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDetailPanel() {
    final crop = _selectedCrop!;
    return FadeTransition(
      opacity: _detailAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_detailAnim),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.accentWarm.withValues(alpha: 0.12),
                AppTheme.card,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppTheme.accentWarm.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(crop.emoji,
                      style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop.cropName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Detailed Profit Analysis',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                      child: _profitStat(
                          'Profit/Ha',
                          '\$${crop.profitPerHectare.toStringAsFixed(0)}',
                          AppTheme.accentWarm)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _profitStat(
                          'Market Price',
                          '\$${crop.marketPrice.toStringAsFixed(0)}/t',
                          AppTheme.accentCool)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _profitStat(
                          'Production',
                          '\$${crop.productionCost.toStringAsFixed(0)}',
                          AppTheme.accentRed)),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Monthly Revenue',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: MiniBarChart(
                  values: crop.monthlyData.map((m) => m.profit).toList(),
                  labels: crop.monthlyData.map((m) => m.month.substring(0, 3)).toList(),
                  color: AppTheme.accentWarm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profitStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = _highProfitSuggestions;
    if (suggestions.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '✨ AI Suggestion',
                style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.accentPurple,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Higher profit crops\nfor your land',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            height: 1.2,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 14),
        ...suggestions.take(3).map((crop) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.accentPurple.withValues(alpha: 0.2),
                      width: 1),
                ),
                child: Row(
                  children: [
                    Text(crop.emoji,
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            crop.cropName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            crop.category,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${crop.profitPerHectare.toStringAsFixed(0)}/ha',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.accentPurple,
                          ),
                        ),
                        Text(
                          '+\$${(crop.profitPerHectare - _selectedCrop!.profitPerHectare).toStringAsFixed(0)} more',
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.accent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
