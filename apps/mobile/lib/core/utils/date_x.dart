import 'package:intl/intl.dart';

/// Date helpers used throughout the app. All habit logging is keyed by the
/// *date only* (midnight, local) so completion is per-calendar-day.
extension DateX on DateTime {
  /// Strips the time component, returning local midnight.
  DateTime get dateOnly => DateTime(year, month, day);

  /// Stable string key for storing per-day records, e.g. "2026-06-07".
  String get key => DateFormat('yyyy-MM-dd').format(this);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool get isToday => isSameDay(DateTime.now());

  String get pretty => DateFormat('EEE, MMM d').format(this);
  String get monthLabel => DateFormat('MMMM yyyy').format(this);
  String get weekdayShort => DateFormat('EEE').format(this);
  String get dayNumber => DateFormat('d').format(this);

  /// Monday of the current week.
  DateTime get startOfWeek =>
      dateOnly.subtract(Duration(days: weekday - 1));

  DateTime get startOfMonth => DateTime(year, month, 1);

  int get daysInMonth => DateTime(year, month + 1, 0).day;
}

/// Inclusive list of [DateTime]s from [start] to [end].
List<DateTime> daysBetween(DateTime start, DateTime end) {
  final s = start.dateOnly;
  final e = end.dateOnly;
  final out = <DateTime>[];
  for (var d = s; !d.isAfter(e); d = d.add(const Duration(days: 1))) {
    out.add(d);
  }
  return out;
}

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}
