import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/completion_tick.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/habit.dart';
import '../../domain/habit_enums.dart';
import '../habit_detail_page.dart';
import '../providers/habit_providers.dart';
import 'status_picker.dart';

/// A single habit row: tap the tick to complete, tap the card for details and
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
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        radius: 18,
        glowColor: done ? habit.color : null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HabitDetailPage(habitId: habit.id),
          ),
        ),
        onLongPress: () => _openPicker(context, ref, status),
        child: Row(
          children: [
            // Icon tile.
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.alpha(habit.color, AppColors.isLight ? 0.12 : 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(habit.icon, color: habit.color, size: 23),
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
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        // Completed reads "settled": slightly quieter title.
                        color: done ? AppColors.muted : AppColors.text),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (status != CompletionStatus.pending) ...[
                        Icon(status.icon, size: 13, color: status.color),
                        const SizedBox(width: 4),
                        Text(status.label,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: status.color)),
                        Container(
                          width: 3,
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 7),
                          decoration: BoxDecoration(
                              color: AppColors.faint, shape: BoxShape.circle),
                        ),
                      ],
                      Icon(Icons.local_fire_department_rounded,
                          size: 13,
                          color: stats.currentStreak > 0
                              ? AppColors.streak
                              : AppColors.faint),
                      const SizedBox(width: 3),
                      Text(
                        '${stats.currentStreak} day${stats.currentStreak == 1 ? '' : 's'}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: stats.currentStreak > 0
                                ? AppColors.muted
                                : AppColors.faint),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Tick(
              done: done,
              color: habit.color,
              onTap: () {
                HapticFeedback.lightImpact();
                ref
                    .read(habitsControllerProvider.notifier)
                    .toggle(habit.id, date);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(
      BuildContext context, WidgetRef ref, CompletionStatus current) async {
    HapticFeedback.mediumImpact();
    final picked =
        await StatusPicker.show(context, habit: habit, current: current);
    if (picked == null) return;
    await ref
        .read(habitsControllerProvider.notifier)
        .setStatus(habit.id, date, picked);
  }
}

/// The completion tick — the premium [CompletionTick] coin with a generous
/// 48px touch target.
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
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: CompletionTick(done: done, color: color, size: 38),
        ),
      ),
    );
  }
}
