import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// How often a habit should be performed.
enum HabitFrequency {
  daily,
  weekly,
  monthly,
  custom;

  String get label => switch (this) {
        HabitFrequency.daily => 'Daily',
        HabitFrequency.weekly => 'Weekly',
        HabitFrequency.monthly => 'Monthly',
        HabitFrequency.custom => 'Custom',
      };
}

enum HabitPriority {
  low,
  medium,
  high;

  String get label => switch (this) {
        HabitPriority.low => 'Low',
        HabitPriority.medium => 'Medium',
        HabitPriority.high => 'High',
      };

  Color get color => switch (this) {
        HabitPriority.low => AppColors.muted,
        HabitPriority.medium => AppColors.secondary,
        HabitPriority.high => AppColors.danger,
      };
}

enum HabitDifficulty {
  easy,
  medium,
  hard;

  String get label => switch (this) {
        HabitDifficulty.easy => 'Easy',
        HabitDifficulty.medium => 'Medium',
        HabitDifficulty.hard => 'Hard',
      };

  /// XP awarded for completing the habit once.
  int get xp => switch (this) {
        HabitDifficulty.easy => 10,
        HabitDifficulty.medium => 20,
        HabitDifficulty.hard => 35,
      };
}

/// The per-day completion state of a habit.
enum CompletionStatus {
  pending,
  completed,
  partial,
  skipped,
  missed,
  postponed;

  String get label => switch (this) {
        CompletionStatus.pending => 'Pending',
        CompletionStatus.completed => 'Completed',
        CompletionStatus.partial => 'Partial',
        CompletionStatus.skipped => 'Skipped',
        CompletionStatus.missed => 'Missed',
        CompletionStatus.postponed => 'Postponed',
      };

  Color get color => switch (this) {
        CompletionStatus.completed => AppColors.success,
        CompletionStatus.partial => AppColors.partial,
        CompletionStatus.skipped => AppColors.skipped,
        CompletionStatus.missed => AppColors.danger,
        CompletionStatus.postponed => AppColors.info,
        CompletionStatus.pending => AppColors.muted,
      };

  IconData get icon => switch (this) {
        CompletionStatus.completed => Icons.check_circle_rounded,
        CompletionStatus.partial => Icons.timelapse_rounded,
        CompletionStatus.skipped => Icons.skip_next_rounded,
        CompletionStatus.missed => Icons.cancel_rounded,
        CompletionStatus.postponed => Icons.schedule_rounded,
        CompletionStatus.pending => Icons.radio_button_unchecked_rounded,
      };

  /// Counts toward streak / completion-rate as a fractional credit.
  double get credit => switch (this) {
        CompletionStatus.completed => 1.0,
        CompletionStatus.partial => 0.5,
        _ => 0.0,
      };
}

T enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
