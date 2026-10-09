import 'dart:math';
import 'package:flutter/material.dart';
import '../models/expense_item.dart';

/// Vẽ biểu đồ cột chi tiêu 7 ngày trong tuần
class WeeklyBarChartPainter extends CustomPainter {
  final List<double> values; // 7 days of amounts
  final List<String> dayLabels; // ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
  final double progress;
  final Color barColor;
  final Color gridColor;
  final Color textColor;

  WeeklyBarChartPainter({
    required this.values,
    required this.dayLabels,
    required this.progress,
    required this.barColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = values.fold<double>(0.0, max);
    final ceiling = maxVal > 0 ? maxVal * 1.2 : 100000.0;

    final bottomPadding = 28.0;
    final topPadding = 20.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final chartWidth = size.width;

    // Draw horizontal dashed grid lines
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.4)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + chartHeight * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    final barCount = values.length;
    if (barCount == 0) return;

    final slotWidth = chartWidth / barCount;
    final barWidth = slotWidth * 0.45;

    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < barCount; i++) {
      final val = values[i];
      final ratio = (val / ceiling).clamp(0.0, 1.0);
      final currentHeight = chartHeight * ratio * progress;

      final left = (i * slotWidth) + (slotWidth - barWidth) / 2;
      final top = topPadding + chartHeight - currentHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, currentHeight),
        const Radius.circular(6),
      );

      // Draw bar with gradient look or solid
      canvas.drawRRect(rect, barPaint);

      // Draw day label on X-axis
      textPainter.text = TextSpan(
        text: dayLabels[i],
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(left + (barWidth - textPainter.width) / 2, size.height - bottomPadding + 8),
      );

      // Draw amount label on top of bar if active
      if (val > 0 && progress > 0.7) {
        final kValue = (val / 1000).round();
        textPainter.text = TextSpan(
          text: '${kValue}k',
          style: TextStyle(
            color: barColor,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(left + (barWidth - textPainter.width) / 2, top - 14),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyBarChartPainter old) =>
      old.progress != progress ||
      old.values != values ||
      old.barColor != barColor;
}

class AnimatedWeeklyBarChart extends StatefulWidget {
  final List<ExpenseItem> expenses;

  const AnimatedWeeklyBarChart({super.key, required this.expenses});

  @override
  State<AnimatedWeeklyBarChart> createState() => _AnimatedWeeklyBarChartState();
}

class _AnimatedWeeklyBarChartState extends State<AnimatedWeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedWeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.forward(from: 0.0);
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

    // Aggregate last 7 days of expenses
    final now = DateTime.now();
    final List<double> values = List.filled(7, 0.0);
    final List<String> labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    for (final exp in widget.expenses) {
      final diffDays = now.difference(exp.date).inDays;
      if (diffDays >= 0 && diffDays < 7) {
        final weekdayIndex = (exp.date.weekday - 1) % 7; // Monday = 0
        values[weekdayIndex] += exp.amount;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      height: 180,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) => CustomPaint(
          size: const Size(double.infinity, 180),
          painter: WeeklyBarChartPainter(
            values: values,
            dayLabels: labels,
            progress: _animation.value,
            barColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
            gridColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            textColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
