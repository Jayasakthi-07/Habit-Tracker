import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../habits/presentation/providers/habit_providers.dart';
import 'gamification_provider.dart';

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.unlocked,
    required this.progress,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool unlocked;
  final double progress; // 0..1
}

/// Computes the list of achievements and their unlock state from real data.
final achievementsProvider = Provider<List<Achievement>>((ref) {
  ref.watch(habitsControllerProvider.select((s) => s.revision));
  final repo = ref.read(habitRepositoryProvider);
  final game = ref.watch(gameProfileProvider);
  final habits = repo.getHabits(includeArchived: true);

  var bestStreak = 0;
  var totalCompleted = 0;
  for (final h in habits) {
    final s = repo.statsFor(h);
    if (s.bestStreak > bestStreak) bestStreak = s.bestStreak;
    totalCompleted += s.totalCompleted;
  }

  Achievement milestone(String id, String title, String desc, IconData icon,
          Color color, num value, num goal) =>
      Achievement(
        id: id,
        title: title,
        description: desc,
        icon: icon,
        color: color,
        unlocked: value >= goal,
        progress: (value / goal).clamp(0, 1).toDouble(),
      );

  return [
    milestone('first_step', 'First Step', 'Create your first habit',
        Icons.flag_rounded, AppColors.primary, habits.length, 1),
    milestone('week_warrior', 'Week Warrior', 'Reach a 7-day streak',
        Icons.local_fire_department_rounded, AppColors.warning, bestStreak, 7),
    milestone('unstoppable', 'Unstoppable', 'Reach a 30-day streak',
        Icons.bolt_rounded, AppColors.secondary, bestStreak, 30),
    milestone('centurion', 'Centurion', 'Complete 100 habits total',
        Icons.military_tech_rounded, AppColors.success, totalCompleted, 100),
    milestone('level_5', 'Rising Star', 'Reach level 5',
        Icons.star_rounded, AppColors.partial, game.level, 5),
    milestone('collector', 'Collector', 'Track 5 different habits',
        Icons.dashboard_customize_rounded, AppColors.info, habits.length, 5),
  ];
});
