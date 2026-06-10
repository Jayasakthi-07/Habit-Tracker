import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/hive_service.dart';
import 'domain/goal.dart';

/// Owns the goal list, persisted in the goals Hive box.
class GoalsController extends Notifier<List<Goal>> {
  static const _uuid = Uuid();

  @override
  List<Goal> build() => _load();

  List<Goal> _load() {
    return HiveService.box(Boxes.goals)
        .values
        .map((m) => Goal.fromJson(m))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> add(Goal goal) async {
    await HiveService.box(Boxes.goals).put(goal.id, goal.toJson());
    state = _load();
  }

  Future<void> create({
    required String title,
    required GoalType type,
    required int target,
    String description = '',
    int colorValue = 0xFF818CF8,
  }) =>
      add(Goal(id: _uuid.v4(), title: title, type: type, target: target, description: description, colorValue: colorValue));

  Future<void> increment(String id, int delta) async {
    final box = HiveService.box(Boxes.goals);
    final raw = box.get(id);
    if (raw == null) return;
    final goal = Goal.fromJson(raw);
    final next = (goal.progress + delta).clamp(0, goal.target);
    await box.put(id, goal.copyWith(progress: next).toJson());
    state = _load();
  }

  Future<void> delete(String id) async {
    await HiveService.box(Boxes.goals).delete(id);
    state = _load();
  }
}

final goalsProvider = NotifierProvider<GoalsController, List<Goal>>(GoalsController.new);
