import 'package:aura_core/aura_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/hive_service.dart';
import '../../core/utils/date_x.dart';
import '../habits/data/habit_repository.dart';
import '../habits/presentation/providers/habit_providers.dart';
import '../journal/journal_provider.dart';

/// One turn in the coach conversation.
class AiMessage {
  const AiMessage({required this.fromUser, required this.text});
  final bool fromUser;
  final String text;
}

class AiCoachState {
  const AiCoachState({
    this.messages = const [],
    this.loading = false,
    this.provider,
  });

  final List<AiMessage> messages;
  final bool loading;
  final AiProviderKind? provider;

  AiCoachState copyWith({
    List<AiMessage>? messages,
    bool? loading,
    AiProviderKind? provider,
  }) =>
      AiCoachState(
        messages: messages ?? this.messages,
        loading: loading ?? this.loading,
        provider: provider ?? this.provider,
      );
}

/// Drives the AI coach: holds the conversation, the selected provider (persisted
/// in the settings box), builds a data-grounded prompt from the user's habits,
/// and calls the configured [AiCoach] (Gemini or OpenAI) via `aura_core`.
class AiCoachController extends Notifier<AiCoachState> {
  static const _kProvider = 'ai_provider';

  static const _system =
      'You are Aura, the AI habit coach built into Aura Habits — a premium '
      'habit-tracking app. Your sole focus is helping the user build and keep '
      'habits using evidence-based behaviour change: habit stacking, tiny/2-minute '
      'habits, streak protection, implementation intentions ("after X, I will Y"), '
      'and identity-based habits ("be the kind of person who…").\n\n'
      'Ground EVERY answer in the user\'s real data provided below — refer to their '
      'actual habit names, streaks, and success rates. Never invent habits or '
      'numbers that are not given. If they have no data, gently coach them to start '
      'one tiny keystone habit.\n\n'
      'Style: warm, direct, motivating, and specific to a habit-tracker context. '
      'Be concise — at most ~4 short sentences or up to 4 bullets. When relevant, '
      'end with ONE concrete next action. Keep advice safe and non-medical.\n\n'
      'Formatting: plain text only. Do NOT use markdown — no **bold**, no #, no '
      'backticks. For lists, start each line with "• ".';

  HabitRepository get _repo => ref.read(habitRepositoryProvider);

  @override
  AiCoachState build() {
    final saved = HiveService.dynBox(Boxes.settings).get(_kProvider) as String?;
    final preferred =
        saved == null ? null : AiProviderKind.fromName(saved, AiProviderKind.gemini);
    return AiCoachState(provider: AiConfig.resolve(preferred));
  }

  bool get isConfigured => AiConfig.anyConfigured;

  /// Providers that actually have a key configured.
  List<AiProviderKind> get availableProviders =>
      AiProviderKind.values.where(AiConfig.isConfigured).toList();

  void setProvider(AiProviderKind kind) {
    HiveService.dynBox(Boxes.settings).put(_kProvider, kind.name);
    state = state.copyWith(provider: kind);
  }

  void clear() => state = state.copyWith(messages: const []);

  Future<void> ask(String question) async {
    final q = question.trim();
    if (q.isEmpty || state.loading) return;

    // Priority chain: preferred/selected provider first, then OpenRouter →
    // OpenAI → Gemini. If the first provider errors, we fall back to the next.
    final chain = AiCoachFactory.fallbackChain(state.provider);
    final history = [...state.messages, AiMessage(fromUser: true, text: q)];

    if (chain.isEmpty) {
      state = state.copyWith(
        messages: [
          ...history,
          const AiMessage(
            fromUser: false,
            text:
                'AI coaching isn\'t set up yet. Add an OpenRouter or OpenAI API '
                'key (see AI_SETUP.md) to unlock your coach.',
          ),
        ],
      );
      return;
    }

    state = state.copyWith(messages: history, loading: true);
    final prompt = _buildPrompt(q);
    String? lastError;
    for (final coach in chain) {
      try {
        final reply = await coach.chat(system: _system, user: prompt);
        state = state.copyWith(
          messages: [...history, AiMessage(fromUser: false, text: reply)],
          loading: false,
          provider: coach.kind, // reflect the provider that actually answered
        );
        return;
      } on AiException catch (e) {
        lastError = e.message; // try the next provider in the chain
      } catch (_) {
        lastError = 'Something went wrong reaching the AI.';
      }
    }

    // Every provider failed.
    state = state.copyWith(
      messages: [
        ...history,
        AiMessage(
            fromUser: false,
            text: '${lastError ?? 'The AI is unavailable.'} Please try again.'),
      ],
      loading: false,
    );
  }

  /// Composes the user turn: a compact snapshot of their habit data followed by
  /// the actual question, so the model answers grounded in reality.
  String _buildPrompt(String question) {
    final repo = _repo;
    final habits = repo.getHabits();
    final today = DateTime.now().dateOnly;
    final b = StringBuffer()..writeln('My habit data:');

    if (habits.isEmpty) {
      b.writeln('- I have no habits yet.');
    } else {
      for (final h in habits) {
        final s = repo.statsFor(h);
        final scheduledToday = h.isScheduledOn(today);
        final doneToday = repo.logFor(h.id, today)?.status.name ?? 'pending';
        b.writeln('- "${h.name}" (${h.frequency.label}, ${h.difficulty.label}): '
            'current streak ${s.currentStreak}, best ${s.bestStreak}, '
            'success ${(s.successRate * 100).round()}%, '
            '${scheduledToday ? 'today: $doneToday' : 'not scheduled today'}.');
      }
    }

    final mood = ref.read(journalProvider.notifier).averageMood;
    if (mood > 0) {
      b.writeln('Recent average mood: ${mood.toStringAsFixed(1)}/5.');
    }

    b
      ..writeln()
      ..writeln('My question: $question');
    return b.toString();
  }
}

final aiCoachProvider =
    NotifierProvider<AiCoachController, AiCoachState>(AiCoachController.new);

/// Quick-start prompts shown when the conversation is empty.
const aiPresetPrompts = <(String, String)>[
  ('Analyze my week', 'How am I doing with my habits this week? Any patterns?'),
  ('Motivate me', 'Give me a short motivational nudge based on my progress.'),
  ('I\'m struggling', 'Which habit am I struggling with most, and how do I fix it?'),
  ('Suggest a habit', 'Based on my current habits, suggest one new habit to add.'),
];
