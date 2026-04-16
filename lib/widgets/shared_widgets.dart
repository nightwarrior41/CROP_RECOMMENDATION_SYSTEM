import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

// ── Gradient Background ───────────────────────────────────────────────────

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.8, -0.8),
          radius: 1.4,
          colors: [Color(0xFF173320), AppTheme.bg],
        ),
      ),
      child: child,
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color color;
  final IconData icon;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit!,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) {
                Text(
                  subtitle!,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMuted),
                );
              }
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

// ── Loading Overlay ───────────────────────────────────────────────────────

class LoadingOverlay extends StatefulWidget {
  final String message;
  const LoadingOverlay({super.key, required this.message});

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnim,
            child: RotationTransition(
              turns: _rotateController,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      AppTheme.accent.withValues(alpha: 0),
                      AppTheme.accent,
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.bg,
                    ),
                    child: const Center(
                      child: Text('🌱', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.message,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Confidence Bar ────────────────────────────────────────────────────────

class ConfidenceBar extends StatefulWidget {
  final double value; // 0.0 – 1.0
  final Color color;
  final double height;

  const ConfidenceBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
  });

  @override
  State<ConfidenceBar> createState() => _ConfidenceBarState();
}

class _ConfidenceBarState extends State<ConfidenceBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: widget.value * _anim.value,
          backgroundColor: widget.color.withValues(alpha: 0.12),
          valueColor: AlwaysStoppedAnimation(widget.color),
          minHeight: widget.height,
        ),
      ),
    );
  }
}

// ── Radar Chart ───────────────────────────────────────────────────────────

class RadarChart extends StatelessWidget {
  final List<double> values; // each 0.0–1.0
  final List<String> labels;
  final Color color;

  const RadarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RadarPainter(values: values, labels: labels, color: color),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color color;

  _RadarPainter({
    required this.values,
    required this.labels,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    final n = values.length;
    final angle = 2 * math.pi / n;

    // Grid rings
    final gridPaint = Paint()
      ..color = AppTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (int i = 0; i <= n; i++) {
        final a = -math.pi / 2 + i * angle;
        final pt = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Axis lines
    for (int i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * angle;
      canvas.drawLine(center,
          Offset(center.dx + radius * math.cos(a), center.dy + radius * math.sin(a)),
          gridPaint);
    }

    // Filled polygon
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path();
    for (int i = 0; i <= n; i++) {
      final a = -math.pi / 2 + (i % n) * angle;
      final r = radius * values[i % n];
      final pt = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    // Dots + labels
    final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * angle;
      final r = radius * values[i];
      final pt = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      canvas.drawCircle(pt, 4, dotPaint);

      // Label
      final lr = radius + 16;
      final lpt = Offset(center.dx + lr * math.cos(a), center.dy + lr * math.sin(a));
      tp.text = TextSpan(
        text: labels[i],
        style: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
      );
      tp.layout();
      tp.paint(canvas, Offset(lpt.dx - tp.width / 2, lpt.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Mini Bar Chart ────────────────────────────────────────────────────────

class MiniBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;

  const MiniBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (i) {
        final normalized = values[i] / maxVal;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 400 + i * 50),
                  curve: Curves.easeOutCubic,
                  height: 60 * normalized,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2 + 0.6 * normalized),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[i],
                  style: const TextStyle(
                      fontSize: 8,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
