import '../../../core/utils/date_x.dart';
import 'habit_enums.dart';

/// A single day's record for a habit. Stored keyed by `habitId|yyyy-MM-dd`.
class HabitLog {
  HabitLog({
    required this.habitId,
    required this.date,
    this.status = CompletionStatus.completed,
    this.progress = 1,
    this.note = '',
  });

  final String habitId;
  final DateTime date;
  final CompletionStatus status;

  /// Count completed toward [Habit.targetPerDay].
  final int progress;
  final String note;

  String get storageKey => keyFor(habitId, date);

  static String keyFor(String habitId, DateTime date) =>
      '$habitId|${date.dateOnly.key}';

  Map<String, dynamic> toJson() => {
        'habitId': habitId,
        'date': date.dateOnly.toIso8601String(),
        'status': status.name,
        'progress': progress,
        'note': note,
      };

  factory HabitLog.fromJson(Map<String, dynamic> json) => HabitLog(
        habitId: json['habitId'] as String,
        date: DateTime.parse(json['date'] as String),
        status: enumFromName(CompletionStatus.values, json['status'] as String?, CompletionStatus.completed),
        progress: json['progress'] as int? ?? 1,
        note: json['note'] as String? ?? '',
      );
}
