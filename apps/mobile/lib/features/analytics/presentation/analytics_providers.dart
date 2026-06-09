import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/domain/habit_category.dart';
import '../../habits/presentation/providers/habit_providers.dart';

class CategoryPerf {
  const CategoryPerf({required this.name, required this.rate, required this.color});
  final String name;
  final double rate;
  final Color color;
}

class HabitSuccess {
  const HabitSuccess({required this.name, required this.rate, required this.color});
  final String name;
  final double rate;
  final Color color;
}

class AnalyticsData {
  const AnalyticsData({
    required this.overallSuccess,
    required this.monthAverage,
    required this.bestHabitName,
    required this.activeDays,
    required this.trend30,
    required this.categoryPerformance,
    required this.habitSuccess,
  });

  final double overallSuccess;
  final double monthAverage;
  final String bestHabitName;
  final int activeDays;
  final List<double> trend30;
  final List<CategoryPerf> categoryPerformance;
  final List<HabitSuccess> habitSuccess;
}

final analyticsProvider = Provider<AnalyticsData>((ref) {
  ref.watch(habitsControllerProvider.select((s) => s.revision));
  final repo = ref.read(habitRepositoryProvider);
  final habits = repo.getHabits();

  final trend = repo.completionTrend(days: 30);
  final monthAvg = trend.isEmpty ? 0.0 : trend.reduce((a, b) => a + b) / trend.length;

  final habitSuccess = <HabitSuccess>[];
  final categoryAgg = <String, List<double>>{};
  var overallNum = 0.0;
  var overallDen = 0;
  var bestName = '—';
  var bestRate = -1.0;

  for (final h in habits) {
    final stats = repo.statsFor(h);
    habitSuccess.add(HabitSuccess(name: h.name, rate: stats.successRate, color: h.color));
    categoryAgg.putIfAbsent(h.categoryId, () => []).add(stats.successRate);
    overallNum += stats.successRate * stats.scheduledElapsed;
    overallDen += stats.scheduledElapsed;
    if (stats.successRate > bestRate && stats.scheduledElapsed > 0) {
      bestRate = stats.successRate;
      bestName = h.name;
    }
  }

  habitSuccess.sort((a, b) => b.rate.compareTo(a.rate));

  final categoryPerf = categoryAgg.entries.map((e) {
    final cat = BuiltInCategories.byId(e.key);
    final avg = e.value.reduce((a, b) => a + b) / e.value.length;
    return CategoryPerf(name: cat.name, rate: avg, color: cat.color);
  }).toList()
    ..sort((a, b) => b.rate.compareTo(a.rate));

  // Active days = number of days in the heatmap with any completion.
  final heatmap = repo.heatmapIntensities();
  final activeDays = heatmap.values.where((v) => v > 0).length;

  return AnalyticsData(
    overallSuccess: overallDen == 0 ? 0 : overallNum / overallDen,
    monthAverage: monthAvg,
    bestHabitName: bestName,
    activeDays: activeDays,
    trend30: trend,
    categoryPerformance: categoryPerf,
    habitSuccess: habitSuccess.take(8).toList(),
  );
});
