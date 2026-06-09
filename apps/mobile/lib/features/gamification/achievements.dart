import 'package:aura_core/aura_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../goals/goals_provider.dart';
import '../habits/presentation/providers/habit_providers.dart';
import '../journal/journal_provider.dart';
import 'gamification_provider.dart';

// Re-export the shared Achievement type so existing imports keep working.
export 'package:aura_core/aura_core.dart' show Achievement;

/// Builds the metric snapshot the shared achievements catalog evaluates against.
/// Computed entirely from local (synced) data so it matches the Windows app.
Map<String, num> buildAchievementMetrics(Ref ref) {
  final repo = ref.read(habitRepositoryProvider);
  final game = ref.watch(gameProfileProvider);
  final habits = repo.getHabits(includeArchived: true);

  var bestStreak = 0;
  var currentStreak = 0;
  var completed = 0;
  var scheduledTotal = 0;
  var creditTotal = 0.0;
  for (final h in habits) {
    final s = repo.statsFor(h);
    if (s.bestStreak > bestStreak) bestStreak = s.bestStreak;
    if (s.currentStreak > currentStreak) currentStreak = s.currentStreak;
    completed += s.totalCompleted;
    creditTotal += s.successRate * s.scheduledElapsed;
    scheduledTotal += s.scheduledElapsed;
  }

  final heatmap = repo.heatmapIntensities(days: 365);
  final activeDays = heatmap.values.where((v) => v > 0).length;
  final perfectDays = heatmap.values.where((v) => v >= 0.999).length;
  final categories = habits.map((h) => h.categoryId).toSet().length;

  final goals = ref.watch(goalsProvider);
  final journal = ref.watch(journalProvider);

  return {
    AchMetric.habits: habits.length,
    AchMetric.bestStreak: bestStreak,
    AchMetric.currentStreak: currentStreak,
    AchMetric.completed: completed,
    AchMetric.level: game.level,
    AchMetric.xp: game.xp,
    AchMetric.activeDays: activeDays,
    AchMetric.perfectDays: perfectDays,
    AchMetric.categories: categories,
    AchMetric.goals: goals.length,
    AchMetric.goalsDone: goals.where((g) => g.isComplete).length,
    AchMetric.journal: journal.length,
    AchMetric.successPct:
        scheduledTotal == 0 ? 0 : (creditTotal / scheduledTotal * 100).round(),
  };
}

/// The full 74-achievement catalog, evaluated against the user's real data.
/// Unlocked first, then by progress — keeps the grid motivating.
final achievementsProvider = Provider<List<Achievement>>((ref) {
  ref.watch(habitsControllerProvider.select((s) => s.revision));
  final metrics = buildAchievementMetrics(ref);
  final all = evaluateAchievements(metrics);
  all.sort((a, b) {
    if (a.unlocked != b.unlocked) return a.unlocked ? -1 : 1;
    return b.progress.compareTo(a.progress);
  });
  return all;
});

/// How many of the catalog are unlocked (for headline stats).
final unlockedCountProvider = Provider<int>((ref) {
  return ref.watch(achievementsProvider).where((a) => a.unlocked).length;
});
