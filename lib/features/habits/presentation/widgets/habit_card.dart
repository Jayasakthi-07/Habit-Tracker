import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
            onPicker: () => showStatusPicker(
              context: context,
              habit: habit,
              current: status,
              onSelect: (s) => ref.read(habitsControllerProvider.notifier).setStatus(habit.id, day, s),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the premium status picker. Uses the dialog's own context to pop (the
/// dialog lives on the root navigator), avoiding the ShellRoute navigator bug.
Future<void> showStatusPicker({
  required BuildContext context,
  required Habit habit,
  required CompletionStatus current,
  required ValueChanged<CompletionStatus> onSelect,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (dialogContext) => _StatusPicker(
      habit: habit,
      current: current,
      onSelect: (s) {
        Navigator.of(dialogContext).pop();
        onSelect(s);
      },
    ),
  );
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

/// Premium circular completion control: tap to toggle, long-press / right-click
/// for the full status picker. Animates the icon, color and a press scale.
class _StatusToggle extends StatefulWidget {
  const _StatusToggle({
    required this.status,
    required this.color,
    required this.onTap,
    required this.onPicker,
  });

  final CompletionStatus status;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onPicker;

  @override
  State<_StatusToggle> createState() => _StatusToggleState();
}

class _StatusToggleState extends State<_StatusToggle> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final done = status == CompletionStatus.completed;
    final active = status != CompletionStatus.pending;
    final ringColor = done
        ? Colors.transparent
        : (active ? status.color : AppColors.borderStrong);

    return Tooltip(
      message: 'Tap to complete · long-press for options',
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.onPicker,
          onSecondaryTap: widget.onPicker,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: done
                    ? LinearGradient(colors: [widget.color, AppColors.secondary])
                    : null,
                color: !done && active ? AppColors.alpha(status.color, 0.16) : Colors.transparent,
                border: Border.all(color: ringColor, width: 2),
                boxShadow: done ? AppShadows.glow(widget.color, strength: 0.18) : null,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
                // Completed shows a clean, bold white check (not a circle-in-a-
                // circle); other active states use their own glyph; pending is a
                // faint check hinting the control is tappable.
                child: Icon(
                  done
                      ? Icons.check_rounded
                      : (active ? status.icon : Icons.check_rounded),
                  key: ValueKey(status),
                  size: done ? 24 : 18,
                  weight: done ? 700 : 400,
                  color: done
                      ? Colors.white
                      : (active ? status.color : AppColors.alpha(AppColors.faint, 0.7)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The premium status-picker dialog content.
class _StatusPicker extends StatelessWidget {
  const _StatusPicker({
    required this.habit,
    required this.current,
    required this.onSelect,
  });

  final Habit habit;
  final CompletionStatus current;
  final ValueChanged<CompletionStatus> onSelect;

  static const _options = <CompletionStatus>[
    CompletionStatus.completed,
    CompletionStatus.partial,
    CompletionStatus.skipped,
    CompletionStatus.postponed,
    CompletionStatus.missed,
    CompletionStatus.pending,
  ];

  String _subtitle(CompletionStatus s) => switch (s) {
        CompletionStatus.completed => 'Full credit toward your streak',
        CompletionStatus.partial => 'Half credit',
        CompletionStatus.skipped => 'Intentionally skipped — no credit',
        CompletionStatus.postponed => 'Moved to another day',
        CompletionStatus.missed => 'Marked as missed',
        CompletionStatus.pending => 'Clear — back to not done',
      };

  String _title(CompletionStatus s) =>
      s == CompletionStatus.pending ? 'Clear status' : s.label;

  @override
  Widget build(BuildContext context) {
    final accent = habit.color;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconBadge(icon: habit.icon, color: accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 2),
                        const Text('How did today go?',
                            style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 6),
              for (final s in _options)
                _StatusOptionTile(
                  status: s,
                  title: _title(s),
                  subtitle: _subtitle(s),
                  selected: s == current,
                  onTap: () => onSelect(s),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 160.ms).scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1, 1),
          curve: Curves.easeOutCubic,
          duration: 200.ms,
        );
  }
}

class _StatusOptionTile extends StatefulWidget {
  const _StatusOptionTile({
    required this.status,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final CompletionStatus status;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_StatusOptionTile> createState() => _StatusOptionTileState();
}

class _StatusOptionTileState extends State<_StatusOptionTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.status == CompletionStatus.pending
        ? AppColors.muted
        : widget.status.color;
    final highlight = widget.selected || _hover;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.alpha(color, 0.12)
                : (_hover ? AppColors.alpha(Colors.white, 0.04) : Colors.transparent),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: widget.selected ? AppColors.alpha(color, 0.45) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.alpha(color, highlight ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(widget.status.icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 1),
                    Text(widget.subtitle,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                  ],
                ),
              ),
              if (widget.selected)
                Icon(Icons.check_circle_rounded, color: color, size: 18)
              else
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.alpha(AppColors.muted, _hover ? 0.9 : 0.35), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
