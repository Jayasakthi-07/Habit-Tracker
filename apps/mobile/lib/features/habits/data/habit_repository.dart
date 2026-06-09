import 'package:uuid/uuid.dart';

import '../../../core/storage/hive_service.dart';
import '../../../core/utils/date_x.dart';
import '../domain/habit.dart';
import '../domain/habit_enums.dart';
import '../domain/habit_log.dart';

/// Aggregated statistics for a single habit.
class HabitStats {
  const HabitStats({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalCompleted,
    required this.successRate,
    required this.scheduledElapsed,
  });

  final int currentStreak;
  final int bestStreak;
  final int totalCompleted;
  final double successRate; // 0..1
  final int scheduledElapsed;
}

/// Repository for habits and their daily logs, backed by Hive. Also hosts the
/// derived analytics (streaks, completion rates, heatmap intensities).
class HabitRepository {
  HabitRepository();

  static const _uuid = Uuid();

  // ---- Habits CRUD ----

  List<Habit> getHabits({bool includeArchived = false}) {
    final box = HiveService.box(Boxes.habits);
    final habits = box.values
        .map((m) => Habit.fromJson(HiveService.cast(m)))
        .where((h) => includeArchived || !h.archived)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return habits;
  }

  Habit? getHabit(String id) {
    final raw = HiveService.box(Boxes.habits).get(id);
    return raw == null ? null : Habit.fromJson(HiveService.cast(raw));
  }

  Future<Habit> upsert(Habit habit) async {
    await HiveService.box(Boxes.habits).put(habit.id, habit.toJson());
    return habit;
  }

  Future<Habit> create(Habit draft) {
    final habit = draft.copyWith();
    return upsert(habit);
  }

  String newId() => _uuid.v4();

  Future<void> delete(String id) async {
    await HiveService.box(Boxes.habits).delete(id);
    // Remove associated logs.
    final logs = HiveService.box(Boxes.logs);
    final keys = logs.keys.where((k) => k.toString().startsWith('$id|')).toList();
    await logs.deleteAll(keys);
  }

  Future<void> setArchived(String id, bool archived) async {
    final habit = getHabit(id);
    if (habit != null) await upsert(habit.copyWith(archived: archived));
  }

  Future<Habit?> duplicate(String id) async {
    final habit = getHabit(id);
    if (habit == null) return null;
    final copy = Habit(
      id: newId(),
      name: '${habit.name} (copy)',
      description: habit.description,
      categoryId: habit.categoryId,
      priority: habit.priority,
      difficulty: habit.difficulty,
      iconCode: habit.iconCode,
      colorValue: habit.colorValue,
      startDate: DateTime.now(),
      endDate: habit.endDate,
      frequency: habit.frequency,
      weekdays: habit.weekdays,
      targetPerDay: habit.targetPerDay,
      reminderTimes: habit.reminderTimes,
      notes: habit.notes,
      sortOrder: getHabits(includeArchived: true).length,
    );
    return upsert(copy);
  }

  // ---- Logs ----

  HabitLog? logFor(String habitId, DateTime date) {
    final raw = HiveService.box(Boxes.logs).get(HabitLog.keyFor(habitId, date));
    return raw == null ? null : HabitLog.fromJson(HiveService.cast(raw));
  }

  List<HabitLog> logsForHabit(String habitId) {
    return HiveService.box(Boxes.logs)
        .values
        .map((m) => HabitLog.fromJson(HiveService.cast(m)))
        .where((l) => l.habitId == habitId)
        .toList();
  }

  List<HabitLog> logsForDate(DateTime date) {
    final key = date.dateOnly.key;
    return HiveService.box(Boxes.logs)
        .values
        .map((m) => HabitLog.fromJson(HiveService.cast(m)))
        .where((l) => l.date.dateOnly.key == key)
        .toList();
  }

  Future<void> setStatus(
    String habitId,
    DateTime date,
    CompletionStatus status, {
    int? progress,
    String? note,
  }) async {
    final box = HiveService.box(Boxes.logs);
    final key = HabitLog.keyFor(habitId, date);
    if (status == CompletionStatus.pending) {
      await box.delete(key);
      return;
    }
    final log = HabitLog(
      habitId: habitId,
      date: date.dateOnly,
      status: status,
      progress: progress ?? (status == CompletionStatus.completed ? 1 : 0),
      note: note ?? '',
    );
    await box.put(key, log.toJson());
  }

  /// Cycles a habit between pending → completed → skipped → pending.
  Future<CompletionStatus> toggle(String habitId, DateTime date) async {
    final current = logFor(habitId, date)?.status ?? CompletionStatus.pending;
    final next = switch (current) {
      CompletionStatus.pending => CompletionStatus.completed,
      CompletionStatus.completed => CompletionStatus.skipped,
      _ => CompletionStatus.pending,
    };
    await setStatus(habitId, date, next);
    return next;
  }

  // ---- Analytics ----

  HabitStats statsFor(Habit habit, {DateTime? asOf}) {
    final today = (asOf ?? DateTime.now()).dateOnly;
    final logs = {for (final l in logsForHabit(habit.id)) l.date.dateOnly.key: l};

    bool doneOn(DateTime d) {
      final l = logs[d.key];
      return l != null && l.status.credit > 0;
    }

    // Current streak (today may be pending without breaking the streak).
    var current = 0;
    for (var d = today; !d.isBefore(habit.startDate.dateOnly); d = d.subtract(const Duration(days: 1))) {
      if (!habit.isScheduledOn(d)) continue;
      if (doneOn(d)) {
        current++;
      } else if (d.isToday) {
        continue;
      } else {
        break;
      }
    }

    // Best streak + totals over all scheduled days.
    var best = 0;
    var run = 0;
    var totalCompleted = 0;
    var scheduledElapsed = 0;
    double credit = 0;
    for (final d in daysBetween(habit.startDate, today)) {
      if (!habit.isScheduledOn(d)) continue;
      scheduledElapsed++;
      final l = logs[d.key];
      if (l != null && l.status.credit > 0) {
        run++;
        best = run > best ? run : best;
        credit += l.status.credit;
        if (l.status == CompletionStatus.completed) totalCompleted++;
      } else {
        run = 0;
      }
    }

    return HabitStats(
      currentStreak: current,
      bestStreak: best,
      totalCompleted: totalCompleted,
      successRate: scheduledElapsed == 0 ? 0 : (credit / scheduledElapsed).clamp(0, 1),
      scheduledElapsed: scheduledElapsed,
    );
  }

  /// Completion intensity (0..1) per day across all active habits, for the
  /// dashboard heatmap.
  Map<DateTime, double> heatmapIntensities({int days = 182}) {
    final habits = getHabits();
    final today = DateTime.now().dateOnly;
    final start = today.subtract(Duration(days: days));
    final result = <DateTime, double>{};

    for (final day in daysBetween(start, today)) {
      final scheduled = habits.where((h) => h.isScheduledOn(day)).toList();
      if (scheduled.isEmpty) continue;
      double credit = 0;
      for (final h in scheduled) {
        final l = logFor(h.id, day);
        credit += l?.status.credit ?? 0;
      }
      result[day] = (credit / scheduled.length).clamp(0, 1);
    }
    return result;
  }

  /// Average completion rate across the last [days] days (0..1).
  List<double> completionTrend({int days = 14}) {
    final habits = getHabits();
    final today = DateTime.now().dateOnly;
    final out = <double>[];
    for (var i = days - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final scheduled = habits.where((h) => h.isScheduledOn(day)).toList();
      if (scheduled.isEmpty) {
        out.add(0);
        continue;
      }
      double credit = 0;
      for (final h in scheduled) {
        credit += logFor(h.id, day)?.status.credit ?? 0;
      }
      out.add((credit / scheduled.length).clamp(0, 1));
    }
    return out;
  }

  /// Today's completion ratio (completed credit / scheduled today).
  ({int total, double completed}) todayProgress() {
    final today = DateTime.now().dateOnly;
    final scheduled = getHabits().where((h) => h.isScheduledOn(today)).toList();
    double credit = 0;
    for (final h in scheduled) {
      credit += logFor(h.id, today)?.status.credit ?? 0;
    }
    return (total: scheduled.length, completed: credit);
  }
}
