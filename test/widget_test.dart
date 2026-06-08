// Basic sanity tests for Aura Habits domain logic.
//
// Widget tests for the full app require Hive + window_manager initialisation,
// so here we unit-test the pure domain rules that power streaks and scheduling.

import 'package:aura_habits/features/habits/domain/habit.dart';
import 'package:aura_habits/features/habits/domain/habit_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Habit scheduling', () {
    test('daily habit is scheduled every day after start', () {
      final habit = Habit(id: '1', name: 'Test', startDate: DateTime(2026, 1, 1));
      expect(habit.isScheduledOn(DateTime(2026, 1, 1)), isTrue);
      expect(habit.isScheduledOn(DateTime(2026, 6, 7)), isTrue);
      expect(habit.isScheduledOn(DateTime(2025, 12, 31)), isFalse);
    });

    test('weekly habit only matches selected weekdays', () {
      final habit = Habit(
        id: '2',
        name: 'Gym',
        startDate: DateTime(2026, 1, 1),
        frequency: HabitFrequency.weekly,
        weekdays: const [DateTime.monday, DateTime.wednesday, DateTime.friday],
      );
      // 2026-06-08 is a Monday.
      expect(habit.isScheduledOn(DateTime(2026, 6, 8)), isTrue);
      // 2026-06-09 is a Tuesday.
      expect(habit.isScheduledOn(DateTime(2026, 6, 9)), isFalse);
    });

    test('end date excludes later days', () {
      final habit = Habit(
        id: '3',
        name: 'Sprint',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
      );
      expect(habit.isScheduledOn(DateTime(2026, 1, 15)), isTrue);
      expect(habit.isScheduledOn(DateTime(2026, 2, 1)), isFalse);
    });
  });

  group('CompletionStatus credit', () {
    test('completed counts full, partial half, others zero', () {
      expect(CompletionStatus.completed.credit, 1.0);
      expect(CompletionStatus.partial.credit, 0.5);
      expect(CompletionStatus.skipped.credit, 0.0);
      expect(CompletionStatus.missed.credit, 0.0);
    });
  });

  group('Habit serialization', () {
    test('round-trips through JSON', () {
      final habit = Habit(
        id: '4',
        name: 'Read',
        startDate: DateTime(2026, 1, 1),
        difficulty: HabitDifficulty.hard,
        priority: HabitPriority.high,
      );
      final restored = Habit.fromJson(habit.toJson());
      expect(restored.name, habit.name);
      expect(restored.difficulty, HabitDifficulty.hard);
      expect(restored.priority, HabitPriority.high);
    });
  });
}
