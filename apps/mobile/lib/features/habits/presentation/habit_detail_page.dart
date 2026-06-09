import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_x.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/heatmap_calendar.dart';
import '../../categories/domain/habit_category.dart';
import '../domain/habit_enums.dart';
import '../domain/habit_log.dart';
import 'providers/habit_providers.dart';
import 'widgets/habit_editor_sheet.dart';

/// Per-habit analytics: streak stats, a 26-week heatmap, weekday performance,
/// and recent activity. Pushed when a habit card is tapped.
class HabitDetailPage extends ConsumerWidget {
  const HabitDetailPage({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(habitsControllerProvider); // rebuild on any change
    final repo = ref.read(habitRepositoryProvider);
    final habit = repo.getHabit(habitId);

    if (habit == null) {
      // Deleted (possibly from the editor) — leave the screen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold(backgroundColor: AppColors.background);
    }

    final stats = repo.statsFor(habit);
    final color = habit.color;
    final category = BuiltInCategories.byId(habit.categoryId);
    final heatmap = repo.habitHeatmap(habit, days: 182);
    final weekday = repo.weekdayPerformance(habit);
    final recent = repo.recentLogs(habit, limit: 10);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Habit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.muted),
            onPressed: () => HabitEditorSheet.show(context, habit: habit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ---- Header ----
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.alpha(color, 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(habit.icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.name,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('${category.name} · ${habit.frequency.label}',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          if (habit.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(habit.description,
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 14, height: 1.5)),
          ],
          const SizedBox(height: 20),

          // ---- Stat grid ----
          Row(
            children: [
              _stat('Current streak', '${stats.currentStreak}',
                  Icons.local_fire_department_rounded, AppColors.warning),
              const SizedBox(width: 12),
              _stat('Best streak', '${stats.bestStreak}',
                  Icons.emoji_events_rounded, AppColors.secondary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat('Completed', '${stats.totalCompleted}',
                  Icons.check_circle_rounded, AppColors.primary),
              const SizedBox(width: 12),
              _stat('Success', '${(stats.successRate * 100).round()}%',
                  Icons.track_changes_rounded, color),
            ],
          ),

          const SizedBox(height: 24),
          Text('Activity', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 7 * 19.0,
              child: HeatmapCalendar(
                  intensities: heatmap, weeks: 26, baseColor: color),
            ),
          ),

          const SizedBox(height: 24),
          Text('By weekday', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GlassCard(child: _WeekdayBars(performance: weekday, color: color)),

          if (recent.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Recent', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final log in recent) _recentRow(log),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(value, style: AppTypography.numeric(24)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _recentRow(HabitLog log) {
    final CompletionStatus status = log.status;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(status.icon, size: 18, color: status.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(log.date.pretty,
                style: const TextStyle(color: AppColors.text, fontSize: 14)),
          ),
          Text(status.label,
              style: TextStyle(color: status.color, fontSize: 13)),
        ],
      ),
    );
  }
}

class _WeekdayBars extends StatelessWidget {
  const _WeekdayBars({required this.performance, required this.color});
  final Map<int, double> performance;
  final Color color;

  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var wd = 1; wd <= 7; wd++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  child: Text(_labels[wd - 1],
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: performance[wd] ?? 0,
                      minHeight: 8,
                      backgroundColor: AppColors.alpha(Colors.white, 0.06),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 38,
                  child: Text('${((performance[wd] ?? 0) * 100).round()}%',
                      textAlign: TextAlign.right,
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 12)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
