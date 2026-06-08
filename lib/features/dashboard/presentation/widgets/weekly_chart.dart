import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_x.dart';

/// Animated bar chart of the last 7 days' completion ratios.
class WeeklyChart extends StatelessWidget {
  const WeeklyChart({super.key, required this.values});

  /// 7 completion ratios (0..1), oldest → newest.
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().dateOnly;
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.cardElevated,
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${(rod.toY * 100).round()}%',
              const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                final date = today.subtract(Duration(days: 6 - i));
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(date.weekdayShort.substring(0, 1),
                      style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.25,
          getDrawingHorizontalLine: (_) => FlLine(color: AppColors.alpha(Colors.white, 0.04), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i] == 0 ? 0.02 : values[i],
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.secondary, AppColors.primary],
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 1,
                    color: AppColors.alpha(Colors.white, 0.04),
                  ),
                ),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
    );
  }
}
