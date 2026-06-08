import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_x.dart';
import '../../data/habit_repository.dart';
import '../../domain/habit.dart';
import '../../domain/habit_enums.dart';

/// Singleton repository instance.
final habitRepositoryProvider = Provider<HabitRepository>((ref) => HabitRepository());

/// Immutable snapshot of the habit list plus a [revision] counter that is
/// bumped on any mutation (including log changes) so derived providers refresh.
class HabitsState {
  const HabitsState({required this.habits, required this.revision, this.showArchived = false});

  final List<Habit> habits;
  final int revision;
  final bool showArchived;

  HabitsState copyWith({List<Habit>? habits, int? revision, bool? showArchived}) =>
      HabitsState(
        habits: habits ?? this.habits,
        revision: revision ?? this.revision,
        showArchived: showArchived ?? this.showArchived,
      );
}

/// Controller that owns habit list state and exposes all mutations.
class HabitsController extends Notifier<HabitsState> {
  HabitRepository get _repo => ref.read(habitRepositoryProvider);

  @override
  HabitsState build() {
    return HabitsState(habits: _repo.getHabits(), revision: 0);
  }

  void _reload() {
    state = state.copyWith(
      habits: _repo.getHabits(includeArchived: state.showArchived),
      revision: state.revision + 1,
    );
  }

  void toggleShowArchived() {
    state = state.copyWith(showArchived: !state.showArchived);
    _reload();
  }

  Future<void> save(Habit habit) async {
    await _repo.upsert(habit);
    _reload();
  }

  Future<void> create(Habit draft) async {
    final ordered = draft.copyWith(sortOrder: state.habits.length);
    await _repo.create(ordered);
    _reload();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _reload();
  }

  Future<void> archive(String id, bool archived) async {
    await _repo.setArchived(id, archived);
    _reload();
  }

  Future<void> duplicate(String id) async {
    await _repo.duplicate(id);
    _reload();
  }

  Future<CompletionStatus> toggleToday(String id) => toggle(id, DateTime.now());

  Future<CompletionStatus> toggle(String id, DateTime date) async {
    final status = await _repo.toggle(id, date);
    _reload();
    return status;
  }

  Future<void> setStatus(String id, DateTime date, CompletionStatus status, {String? note}) async {
    await _repo.setStatus(id, date, status, note: note);
    _reload();
  }
}

final habitsControllerProvider =
    NotifierProvider<HabitsController, HabitsState>(HabitsController.new);

/// Habits scheduled for today, in display order.
final todayHabitsProvider = Provider<List<Habit>>((ref) {
  final state = ref.watch(habitsControllerProvider);
  final today = DateTime.now().dateOnly;
  return state.habits.where((h) => !h.archived && h.isScheduledOn(today)).toList();
});

/// Stats for a single habit, recomputed whenever the revision changes.
final habitStatsProvider = Provider.family<HabitStats, String>((ref, id) {
  ref.watch(habitsControllerProvider.select((s) => s.revision));
  final repo = ref.read(habitRepositoryProvider);
  final habit = repo.getHabit(id);
  if (habit == null) {
    return const HabitStats(currentStreak: 0, bestStreak: 0, totalCompleted: 0, successRate: 0, scheduledElapsed: 0);
  }
  return repo.statsFor(habit);
});

/// Today's status for a habit.
final todayStatusProvider = Provider.family<CompletionStatus, String>((ref, id) {
  ref.watch(habitsControllerProvider.select((s) => s.revision));
  final repo = ref.read(habitRepositoryProvider);
  return repo.logFor(id, DateTime.now())?.status ?? CompletionStatus.pending;
});

/// Status for a habit on a specific day (used by the calendar).
final statusOnProvider =
    Provider.family<CompletionStatus, ({String id, DateTime date})>((ref, arg) {
  ref.watch(habitsControllerProvider.select((s) => s.revision));
  final repo = ref.read(habitRepositoryProvider);
  return repo.logFor(arg.id, arg.date)?.status ?? CompletionStatus.pending;
});
