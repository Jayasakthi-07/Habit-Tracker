import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../habits/domain/habit_enums.dart';
import '../habits/presentation/providers/habit_providers.dart';

/// Player progression derived from completion history.
class GameProfile {
  const GameProfile({
    required this.xp,
    required this.level,
    required this.coins,
    required this.levelFloor,
    required this.levelCeil,
  });

  final int xp;
  final int level;
  final int coins;
  final int levelFloor; // XP at start of current level
  final int levelCeil; // XP needed for next level

  double get levelProgress {
    final span = (levelCeil - levelFloor);
    if (span <= 0) return 1;
    return ((xp - levelFloor) / span).clamp(0, 1);
  }

  int get xpToNext => (levelCeil - xp).clamp(0, levelCeil);
}

/// XP required to *reach* a given level (quadratic curve).
int _xpForLevel(int level) => (level - 1) * (level - 1) * 100;

GameProfile _profileFromXp(int xp) {
  var level = 1;
  while (_xpForLevel(level + 1) <= xp) {
    level++;
  }
  return GameProfile(
    xp: xp,
    level: level,
    coins: xp ~/ 10,
    levelFloor: _xpForLevel(level),
    levelCeil: _xpForLevel(level + 1),
  );
}

/// Aggregates XP from every completed/partial log, weighted by difficulty.
final gameProfileProvider = Provider<GameProfile>((ref) {
  ref.watch(habitsControllerProvider.select((s) => s.revision));
  final repo = ref.read(habitRepositoryProvider);
  final habits = {for (final h in repo.getHabits(includeArchived: true)) h.id: h};

  var xp = 0;
  for (final habit in habits.values) {
    for (final log in repo.logsForHabit(habit.id)) {
      final base = habit.difficulty.xp;
      if (log.status == CompletionStatus.completed) {
        xp += base;
      } else if (log.status == CompletionStatus.partial) {
        xp += (base * 0.5).round();
      }
    }
  }
  return _profileFromXp(xp);
});
