import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/habit.dart';
import '../../domain/habit_enums.dart';
import '../habit_detail_page.dart';
import '../providers/habit_providers.dart';
import 'status_picker.dart';

/// A single habit row: tap the tick to complete, tap the card to edit, and
/// long-press for the full status picker. Shows current streak + today's state.
class HabitCard extends ConsumerWidget {
  const HabitCard({super.key, required this.habit, required this.date});

  final Habit habit;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(statusOnProvider((id: habit.id, date: date)));
    final stats = ref.watch(habitStatsProvider(habit.id));
    final done = status == CompletionStatus.completed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        glowColor: done ? habit.color : null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HabitDetailPage(habitId: habit.id),
          ),
        ),
        onLongPress: () => _openPicker(context, ref, status),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.alpha(habit.color, 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(habit.icon, color: habit.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (status != CompletionStatus.pending) ...[
                        Icon(status.icon, size: 13, color: status.color),
                        const SizedBox(width: 4),
                        Text(status.label,
                            style: TextStyle(fontSize: 12, color: status.color)),
                        const SizedBox(width: 10),
                      ],
                      Icon(Icons.local_fire_department_rounded,
                          size: 13,
                          color: stats.currentStreak > 0
                              ? AppColors.warning
                              : AppColors.faint),
                      const SizedBox(width: 3),
                      Text('${stats.currentStreak}',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Tick(
              done: done,
              color: habit.color,
              onTap: () => ref
                  .read(habitsControllerProvider.notifier)
                  .toggle(habit.id, date),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(
      BuildContext context, WidgetRef ref, CompletionStatus current) async {
    final picked =
        await StatusPicker.show(context, habit: habit, current: current);
    if (picked == null) return;
    await ref
        .read(habitsControllerProvider.notifier)
        .setStatus(habit.id, date, picked);
  }
}

/// The completion tick — a clean bold check when done, an empty ring otherwise.
class _Tick extends StatelessWidget {
  const _Tick({required this.done, required this.color, required this.onTap});
  final bool done;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppSpacing.fast,
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: done
              ? LinearGradient(colors: [color, AppColors.secondary])
              : null,
          border: done ? null : Border.all(color: AppColors.borderStrong, width: 1.5),
        ),
        child: done
            ? const Icon(Icons.check_rounded,
                color: Colors.white, size: 22, weight: 700)
            : null,
      ),
    );
  }
}
