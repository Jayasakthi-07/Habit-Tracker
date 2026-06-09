import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glow_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../export/export_service.dart';
import '../../habits/presentation/providers/habit_providers.dart';
import 'analytics_providers.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitsControllerProvider);
    if (state.habits.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.insights_rounded,
          title: 'No data yet',
          message: 'Create and track habits to unlock rich analytics and insights.',
        ),
      );
    }

    final analytics = ref.watch(analyticsProvider);

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Analytics',
            subtitle: 'Insights across all your habits',
            icon: Icons.insights_rounded,
            trailing: Row(children: [
              GlowButton(
                label: 'Export CSV',
                icon: Icons.table_chart_rounded,
                variant: GlowButtonVariant.ghost,
                onPressed: () => ExportService.instance.exportCsv(ref, context),
              ),
              const SizedBox(width: 8),
              GlowButton(
                label: 'Export PDF',
                icon: Icons.picture_as_pdf_rounded,
                onPressed: () => ExportService.instance.exportPdf(ref, context),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _Kpi(label: 'Overall success', value: '${(analytics.overallSuccess * 100).round()}%', color: AppColors.primary, icon: Icons.verified_rounded),
              const SizedBox(width: 14),
              _Kpi(label: '30-day average', value: '${(analytics.monthAverage * 100).round()}%', color: AppColors.secondary, icon: Icons.calendar_month_rounded),
              const SizedBox(width: 14),
              _Kpi(label: 'Best habit', value: analytics.bestHabitName, color: AppColors.warning, icon: Icons.star_rounded, small: true),
              const SizedBox(width: 14),
              _Kpi(label: 'Most consistent', value: '${analytics.activeDays} active days', color: AppColors.info, icon: Icons.event_available_rounded, small: true),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Completion Trend', subtitle: 'Last 30 days', icon: Icons.show_chart_rounded),
                const SizedBox(height: 24),
                SizedBox(height: 220, child: _TrendChart(values: analytics.trend30)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Category Performance', icon: Icons.donut_large_rounded),
                      const SizedBox(height: 20),
                      SizedBox(height: 230, child: _CategoryChart(data: analytics.categoryPerformance)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Habit Consistency', icon: Icons.leaderboard_rounded),
                      const SizedBox(height: 16),
                      for (final h in analytics.habitSuccess)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _HabitBar(name: h.name, value: h.rate, color: h.color),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, required this.color, required this.icon, this.small = false});
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        hoverable: true,
        glowColor: color,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 14),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.numeric(small ? 18 : 26)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.values});
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.25,
          getDrawingHorizontalLine: (_) => FlLine(color: AppColors.alpha(Colors.white, 0.04), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 0.5,
              getTitlesWidget: (v, _) => Text('${(v * 100).round()}%',
                  style: TextStyle(fontSize: 10, color: AppColors.muted)),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
            isCurved: true,
            curveSmoothness: 0.3,
            gradient: AppColors.accentGlow,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.alpha(AppColors.primary, 0.25), Colors.transparent],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 700),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.data});
  final List<CategoryPerf> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(child: Text('No category data', style: TextStyle(color: AppColors.muted)));
    }
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 44,
              sections: [
                for (final c in data)
                  PieChartSectionData(
                    value: c.rate <= 0 ? 0.5 : c.rate * 100,
                    color: c.color,
                    radius: 50,
                    showTitle: false,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final c in data.take(7))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(width: 9, height: 9, decoration: BoxDecoration(color: c.color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                      Text('${(c.rate * 100).round()}%', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HabitBar extends StatelessWidget {
  const _HabitBar({required this.name, required this.value, required this.color});
  final String name;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
            Text('${(value * 100).round()}%', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 7,
              backgroundColor: AppColors.alpha(Colors.white, 0.06),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}
