import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../habits/data/habit_repository.dart';
import '../habits/domain/habit.dart';
import '../habits/presentation/providers/habit_providers.dart';

/// A single AI-generated insight or suggestion.
class AiInsight {
  const AiInsight({required this.title, required this.body, required this.kind});
  final String title;
  final String body;
  final AiInsightKind kind;
}

enum AiInsightKind { suggestion, analysis, motivation, risk }

/// AI-ready service layer.
///
/// Today this produces useful insights using local heuristics over the user's
/// data, so the feature works fully offline. The [generate] surface is designed
/// to be swapped for a hosted LLM API (e.g. the Anthropic Messages API) without
/// touching the UI: implement [_remote] and flip [useRemote].
abstract class AiService {
  /// Wire this to a real backend later. Kept false so the app is fully offline.
  static const bool useRemote = false;

  static Future<List<AiInsight>> generate(HabitRepository repo) async {
    if (useRemote) return _remote(repo);
    return _local(repo);
  }

  // ---- Future online implementation placeholder ----
  static Future<List<AiInsight>> _remote(HabitRepository repo) async {
    // TODO: POST anonymised stats to the AI endpoint and map the response.
    throw UnimplementedError('Remote AI not configured');
  }

  // ---- Local heuristic engine ----
  static List<AiInsight> _local(HabitRepository repo) {
    final habits = repo.getHabits();
    final insights = <AiInsight>[];

    if (habits.isEmpty) {
      insights.add(const AiInsight(
        kind: AiInsightKind.suggestion,
        title: 'Start small',
        body: 'Pick one keystone habit — like a 10-minute walk or reading 2 pages. '
            'Consistency on something small builds the identity for bigger habits.',
      ));
      return insights;
    }

    // Risk prediction: habits with a strong streak but skipped today.
    for (final h in habits) {
      final stats = repo.statsFor(h);
      final today = repo.logFor(h.id, DateTime.now());
      if (stats.currentStreak >= 3 && (today == null) && h.isScheduledOn(DateTime.now())) {
        insights.add(AiInsight(
          kind: AiInsightKind.risk,
          title: 'Protect your ${h.name} streak',
          body: 'You\'re on a ${stats.currentStreak}-day streak but haven\'t logged it today. '
              'A 2-minute version still counts — keep the chain alive.',
        ));
      }
    }

    // Analysis: lowest performing habit.
    final ranked = [...habits]..sort((a, b) => repo.statsFor(a).successRate.compareTo(repo.statsFor(b).successRate));
    final weakest = ranked.first;
    final weakestRate = repo.statsFor(weakest).successRate;
    if (weakestRate < 0.5) {
      insights.add(AiInsight(
        kind: AiInsightKind.analysis,
        title: '${weakest.name} needs attention',
        body: 'This habit is at ${(weakestRate * 100).round()}% success. Try pairing it with an '
            'existing routine (habit stacking) or lowering the target to rebuild momentum.',
      ));
    }

    // Suggestion based on categories the user lacks.
    final present = habits.map((h) => h.categoryId).toSet();
    if (!present.contains('meditation') && !present.contains('sleep')) {
      insights.add(const AiInsight(
        kind: AiInsightKind.suggestion,
        title: 'Add a recovery habit',
        body: 'Your habits focus on output. Consider a recovery habit like a short meditation '
            'or a consistent sleep time — it compounds the results of everything else.',
      ));
    }

    // Motivation.
    final bestStreak = habits.map((h) => repo.statsFor(h).bestStreak).fold<int>(0, (a, b) => a > b ? a : b);
    insights.add(AiInsight(
      kind: AiInsightKind.motivation,
      title: 'You\'re building something',
      body: bestStreak > 0
          ? 'Your best streak so far is $bestStreak days — proof you can do this. '
              'Aim to beat it this month.'
          : 'Every expert was once a beginner. Log one habit today and start your first streak.',
    ));

    return insights;
  }

  /// Suggested new habits the user might want (static catalogue for now).
  static List<({String name, String category})> suggestedHabits(List<Habit> existing) {
    final have = existing.map((h) => h.name.toLowerCase()).toSet();
    const catalogue = [
      (name: 'Drink water', category: 'health'),
      (name: 'Morning walk', category: 'fitness'),
      (name: 'Read 10 pages', category: 'reading'),
      (name: 'Meditate', category: 'meditation'),
      (name: 'Plan tomorrow', category: 'productivity'),
      (name: 'No phone after 10pm', category: 'sleep'),
      (name: 'Stretch', category: 'fitness'),
      (name: 'Gratitude journaling', category: 'spiritual'),
    ];
    return catalogue.where((c) => !have.contains(c.name.toLowerCase())).take(6).toList();
  }
}

final aiInsightsProvider = FutureProvider<List<AiInsight>>((ref) async {
  ref.watch(habitsControllerProvider.select((s) => s.revision));
  return AiService.generate(ref.read(habitRepositoryProvider));
});
