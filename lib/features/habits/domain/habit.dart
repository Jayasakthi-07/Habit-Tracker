import 'package:flutter/material.dart';

import 'habit_enums.dart';
import '../../../core/theme/app_colors.dart';

/// Core domain entity representing a single habit the user is tracking.
///
/// Serialised to/from JSON for storage in Hive (no codegen required), which
/// keeps the model dependency-free and easy to evolve.
@immutable
class Habit {
  const Habit({
    required this.id,
    required this.name,
    this.description = '',
    this.categoryId = 'health',
    this.priority = HabitPriority.medium,
    this.difficulty = HabitDifficulty.medium,
    this.iconCode = 0xe87d, // favorite
    this.colorValue = 0xFF818CF8,
    required this.startDate,
    this.endDate,
    this.frequency = HabitFrequency.daily,
    this.weekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.targetPerDay = 1,
    this.reminderTimes = const [],
    this.notes = '',
    this.archived = false,
    this.createdAt,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String description;
  final String categoryId;
  final HabitPriority priority;
  final HabitDifficulty difficulty;
  final int iconCode;
  final int colorValue;
  final DateTime startDate;
  final DateTime? endDate;
  final HabitFrequency frequency;

  /// Which weekdays (DateTime.monday..sunday) the habit is scheduled on.
  /// Used for weekly/custom frequencies.
  final List<int> weekdays;

  /// How many times per day counts as "complete" (e.g. 8 glasses of water).
  final int targetPerDay;

  /// Reminder times stored as "HH:mm" strings (supports multiple reminders).
  final List<String> reminderTimes;

  final String notes;
  final bool archived;
  final DateTime? createdAt;
  final int sortOrder;

  // Icons are user-selected at runtime, so the codePoint is intentionally
  // dynamic (build with --no-tree-shake-icons).
  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => AppColors.habitColor(colorValue);

  /// Whether this habit is scheduled on [date] given its frequency.
  bool isScheduledOn(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    if (d.isBefore(DateTime(startDate.year, startDate.month, startDate.day))) {
      return false;
    }
    if (endDate != null &&
        d.isAfter(DateTime(endDate!.year, endDate!.month, endDate!.day))) {
      return false;
    }
    return switch (frequency) {
      HabitFrequency.daily => true,
      HabitFrequency.weekly || HabitFrequency.custom =>
        weekdays.contains(d.weekday),
      HabitFrequency.monthly => d.day == startDate.day,
    };
  }

  Habit copyWith({
    String? name,
    String? description,
    String? categoryId,
    HabitPriority? priority,
    HabitDifficulty? difficulty,
    int? iconCode,
    int? colorValue,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    HabitFrequency? frequency,
    List<int>? weekdays,
    int? targetPerDay,
    List<String>? reminderTimes,
    String? notes,
    bool? archived,
    int? sortOrder,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      difficulty: difficulty ?? this.difficulty,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      frequency: frequency ?? this.frequency,
      weekdays: weekdays ?? this.weekdays,
      targetPerDay: targetPerDay ?? this.targetPerDay,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      notes: notes ?? this.notes,
      archived: archived ?? this.archived,
      createdAt: createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'categoryId': categoryId,
        'priority': priority.name,
        'difficulty': difficulty.name,
        'iconCode': iconCode,
        'colorValue': colorValue,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'frequency': frequency.name,
        'weekdays': weekdays,
        'targetPerDay': targetPerDay,
        'reminderTimes': reminderTimes,
        'notes': notes,
        'archived': archived,
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
        'sortOrder': sortOrder,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        categoryId: json['categoryId'] as String? ?? 'health',
        priority: enumFromName(HabitPriority.values, json['priority'] as String?, HabitPriority.medium),
        difficulty: enumFromName(HabitDifficulty.values, json['difficulty'] as String?, HabitDifficulty.medium),
        iconCode: json['iconCode'] as int? ?? 0xe87d,
        colorValue: json['colorValue'] as int? ?? 0xFF818CF8,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
        frequency: enumFromName(HabitFrequency.values, json['frequency'] as String?, HabitFrequency.daily),
        weekdays: (json['weekdays'] as List?)?.map((e) => e as int).toList() ?? const [1, 2, 3, 4, 5, 6, 7],
        targetPerDay: json['targetPerDay'] as int? ?? 1,
        reminderTimes: (json['reminderTimes'] as List?)?.map((e) => e as String).toList() ?? const [],
        notes: json['notes'] as String? ?? '',
        archived: json['archived'] as bool? ?? false,
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );
}
