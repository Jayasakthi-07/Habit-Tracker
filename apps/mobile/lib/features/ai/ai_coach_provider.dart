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
      'You are Aura, a warm, sharp habit coach inside the Aura Habits app. '
      'Use the user\'s real habit data (provided below) to give specific, '
      'actionable, encouraging advice. Be concise — 2-4 short paragraphs or a '
      'tight bullet list. Never invent data that isn\'t given. Speak directly '
      'to the user ("you").';

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

    final coach = AiCoachFactory.resolve(state.provider);
    final history = [...state.messages, AiMessage(fromUser: true, text: q)];

    if (coach == null) {
      state = state.copyWith(
        messages: [
          ...history,
          const AiMessage(
            fromUser: false,
            text:
                'AI coaching isn\'t set up yet. Add a Gemini or OpenAI API key '
                '(see the setup guide) to unlock your coach.',
          ),
        ],
      );
      return;
    }

    state = state.copyWith(messages: history, loading: true);
    try {
      final reply = await coach.chat(system: _system, user: _buildPrompt(q));
      state = state.copyWith(
        messages: [...history, AiMessage(fromUser: false, text: reply)],
        loading: false,
      );
    } on AiException catch (e) {
      state = state.copyWith(
        messages: [...history, AiMessage(fromUser: false, text: e.message)],
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(
        messages: [
          ...history,
          const AiMessage(
              fromUser: false,
              text: 'Something went wrong reaching the AI. Please try again.'),
        ],
        loading: false,
      );
    }
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
