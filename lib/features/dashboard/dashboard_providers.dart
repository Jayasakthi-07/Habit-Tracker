import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../habits/presentation/providers/habit_providers.dart';

/// Aggregate dashboard metrics derived from the habit repository.
class DashboardMetrics {
  const DashboardMetrics({
    required this.todayCompletion,
    required this.todayDone,
    required this.todayTotal,
    required this.bestStreak,
    required this.currentBestStreak,
    required this.totalCompleted,
    required this.activeHabits,
  });

  final double todayCompletion; // 0..1
  final int todayDone;
  final int todayTotal;
  final int bestStreak;
  final int currentBestStreak; // best *current* streak among habits
  final int totalCompleted;
  final int activeHabits;
}

final dashboardMetricsProvider = Provider<DashboardMetrics>((ref) {
  ref.watch(habitsControllerProvider.select((s) => s.revision));
  final repo = ref.read(habitRepositoryProvider);
  final habits = repo.getHabits();

  final today = repo.todayProgress();
  var best = 0;
  var currentBest = 0;
  var totalCompleted = 0;
  for (final h in habits) {
    final s = repo.statsFor(h);
    if (s.bestStreak > best) best = s.bestStreak;
    if (s.currentStreak > currentBest) currentBest = s.currentStreak;
    totalCompleted += s.totalCompleted;
  }

  return DashboardMetrics(
    todayCompletion: today.total == 0 ? 0 : (today.completed / today.total).clamp(0, 1),
    todayDone: today.completed.round(),
    todayTotal: today.total,
    bestStreak: best,
    currentBestStreak: currentBest,
    totalCompleted: totalCompleted,
    activeHabits: habits.length,
  );
});

/// Completion ratio for each of the last 7 days (oldest → newest).
final weeklyBarsProvider = Provider<List<double>>((ref) {
  ref.watch(habitsControllerProvider.select((s) => s.revision));
  return ref.read(habitRepositoryProvider).completionTrend(days: 7);
});

/// Heatmap intensities for the dashboard contribution grid.
final heatmapProvider = Provider((ref) {
  ref.watch(habitsControllerProvider.select((s) => s.revision));
  return ref.read(habitRepositoryProvider).heatmapIntensities();
});
