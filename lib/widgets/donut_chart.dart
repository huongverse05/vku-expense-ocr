import 'dart:math';
import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../models/expense_category.dart';

/// Vẽ biểu đồ Donut phân loại danh mục
class DonutChartPainter extends CustomPainter {
  final List<double> percentages; // [0.4, 0.35, 0.25]
  final List<Color> colors;
  final double progress; // 0.0 -> 1.0
  final Color backgroundColor;

  DonutChartPainter({
    required this.percentages,
    required this.colors,
    required this.progress,
    this.backgroundColor = const Color(0xFFE2E8F0),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 16;
    const strokeWidth = 24.0;

    // Draw background track ring
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = backgroundColor.withOpacity(0.35);

    canvas.drawCircle(center, radius, bgPaint);

    if (percentages.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -pi / 2;

    for (int i = 0; i < percentages.length; i++) {
      final p = percentages[i];
      if (p <= 0.001) continue;

      final sweep = (2 * pi * p) * progress;
      paint.color = colors[i % colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter old) =>
      old.progress != progress ||
      old.percentages != percentages ||
      old.colors != colors;
}

/// Animated Donut Chart Widget hosting the CustomPainter with AnimationController
class AnimatedCategoryDonutChart extends StatefulWidget {
  final Map<ExpenseCategory, double> categoryTotals;
  final double totalAmount;

  const AnimatedCategoryDonutChart({
    super.key,
    required this.categoryTotals,
    required this.totalAmount,
  });

  @override
  State<AnimatedCategoryDonutChart> createState() =>
      _AnimatedCategoryDonutChartState();
}

class _AnimatedCategoryDonutChartState extends State<AnimatedCategoryDonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedCategoryDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalAmount != widget.totalAmount) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final nonZeroEntries = widget.categoryTotals.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = widget.totalAmount > 0 ? widget.totalAmount : 1.0;
    final percentages = nonZeroEntries.map((e) => e.value / total).toList();
    final colors = nonZeroEntries.map((e) => e.key.color).toList();

    return Column(
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, _) => CustomPaint(
                  size: const Size(220, 220),
                  painter: DonutChartPainter(
                    percentages: percentages,
                    colors: colors,
                    progress: _animation.value,
                    backgroundColor: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
              // Center metric label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tổng chi tiêu',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatCurrency(widget.totalAmount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF1E3A5F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${nonZeroEntries.length} danh mục',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Categories Breakdown Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: nonZeroEntries.map((entry) {
            final pct = (entry.value / total * 100).toStringAsFixed(1);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: entry.key.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${entry.key.displayName}: $pct%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF334155),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
