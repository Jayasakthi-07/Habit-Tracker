import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/hive_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_x.dart';

/// Mood levels for daily mood tracking.
enum Mood {
  awful(1, '😞', 'Awful', AppColors.danger),
  bad(2, '😕', 'Bad', Color(0xFFFF8A65)),
  okay(3, '😐', 'Okay', AppColors.warning),
  good(4, '🙂', 'Good', Color(0xFF38BDF8)),
  great(5, '😄', 'Great', Color(0xFF6366F1));

  const Mood(this.score, this.emoji, this.label, this.color);
  final int score;
  final String emoji;
  final String label;
  final Color color;

  static Mood fromScore(int s) => Mood.values.firstWhere((m) => m.score == s, orElse: () => Mood.okay);
}

class JournalEntry {
  JournalEntry({required this.date, required this.mood, this.text = ''});

  final DateTime date;
  final Mood mood;
  final String text;

  Map<String, dynamic> toJson() => {
        'date': date.dateOnly.toIso8601String(),
        'mood': mood.score,
        'text': text,
      };

  factory JournalEntry.fromJson(Map json) => JournalEntry(
        date: DateTime.parse(json['date'] as String),
        mood: Mood.fromScore(json['mood'] as int? ?? 3),
        text: json['text'] as String? ?? '',
      );
}

class JournalController extends Notifier<List<JournalEntry>> {
  @override
  List<JournalEntry> build() => _load();

  List<JournalEntry> _load() {
    return HiveService.box(Boxes.journal)
        .values
        .map((m) => JournalEntry.fromJson(m))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  JournalEntry? entryFor(DateTime date) {
    final raw = HiveService.box(Boxes.journal).get(date.dateOnly.key);
    return raw == null ? null : JournalEntry.fromJson(raw);
  }

  Future<void> save(DateTime date, Mood mood, String text) async {
    final entry = JournalEntry(date: date.dateOnly, mood: mood, text: text);
    await HiveService.box(Boxes.journal).put(date.dateOnly.key, entry.toJson());
    state = _load();
  }

  Future<void> delete(DateTime date) async {
    await HiveService.box(Boxes.journal).delete(date.dateOnly.key);
    state = _load();
  }

  /// Average mood over recent entries (1..5).
  double get averageMood {
    if (state.isEmpty) return 0;
    return state.map((e) => e.mood.score).reduce((a, b) => a + b) / state.length;
  }
}

final journalProvider = NotifierProvider<JournalController, List<JournalEntry>>(JournalController.new);
