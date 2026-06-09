import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/streak_flame.dart';
import '../../../categories/domain/habit_category.dart';
import '../../domain/habit.dart';
import '../../domain/habit_enums.dart';
import '../providers/habit_providers.dart';

/// A rich habit row used in lists and the dashboard. Shows category, streak and
/// a tappable completion control that cycles the day's status.
class HabitCard extends ConsumerWidget {
  const HabitCard({super.key, required this.habit, this.date, this.onEdit});

  final Habit habit;
  final DateTime? date;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = date ?? DateTime.now();
    final stats = ref.watch(habitStatsProvider(habit.id));
    final status = ref.watch(statusOnProvider((id: habit.id, date: day)));
    final category = BuiltInCategories.byId(habit.categoryId);
    final accent = habit.color;

    return GlassCard(
      hoverable: true,
      glowColor: accent,
      padding: const EdgeInsets.all(16),
      onTap: onEdit,
      child: Row(
        children: [
          _IconBadge(icon: habit.icon, color: accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habit.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(category.icon, size: 12, color: AppColors.muted),
                    const SizedBox(width: 5),
                    Text(category.name, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    const SizedBox(width: 12),
                    StreakFlame(streak: stats.currentStreak, size: 14),
                  ],
                ),
              ],
            ),
          ),
          _PriorityDot(priority: habit.priority),
          const SizedBox(width: 14),
          _StatusToggle(
            status: status,
            color: accent,
            onTap: () => ref.read(habitsControllerProvider.notifier).toggle(habit.id, day),
            onLongPress: () => _showStatusSheet(context, ref, day),
          ),
        ],
      ),
    );
  }

  void _showStatusSheet(BuildContext context, WidgetRef ref, DateTime day) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set status — ${habit.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 16),
              for (final s in [
                CompletionStatus.completed,
                CompletionStatus.partial,
                CompletionStatus.skipped,
                CompletionStatus.postponed,
                CompletionStatus.missed,
                CompletionStatus.pending,
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(s.icon, color: s.color),
                  title: Text(s.label),
                  onTap: () {
                    ref.read(habitsControllerProvider.notifier).setStatus(habit.id, day, s);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.alpha(color, 0.14),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.alpha(color, 0.3)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});
  final HabitPriority priority;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${priority.label} priority',
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: priority.color, shape: BoxShape.circle),
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({
    required this.status,
    required this.color,
    required this.onTap,
    required this.onLongPress,
  });

  final CompletionStatus status;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final done = status == CompletionStatus.completed;
    final active = status != CompletionStatus.pending;
    return Tooltip(
      message: 'Click to toggle • long-press for more',
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: AppSpacing.fast,
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: done ? LinearGradient(colors: [color, AppColors.secondary]) : null,
            color: !done && active ? AppColors.alpha(status.color, 0.18) : Colors.transparent,
            border: Border.all(
              color: done ? Colors.transparent : (active ? status.color : AppColors.borderStrong),
              width: 1.5,
            ),
            boxShadow: done ? AppShadows.glow(color, strength: 0.2) : null,
          ),
          child: Icon(
            active ? status.icon : Icons.check_rounded,
            size: 18,
            color: done ? const Color(0xFF002417) : (active ? status.color : AppColors.faint),
          ),
        ),
      ),
    );
  }
}
