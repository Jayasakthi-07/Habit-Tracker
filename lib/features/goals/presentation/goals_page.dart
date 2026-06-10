import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glow_button.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../../shared/widgets/section_header.dart';
import '../domain/goal.dart';
import '../goals_provider.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Goals',
              subtitle: '${goals.where((g) => g.isComplete).length} of ${goals.length} achieved',
              icon: Icons.flag_rounded,
              trailing: GlowButton(
                label: 'New goal',
                icon: Icons.add_rounded,
                onPressed: () => _showGoalDialog(context, ref),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: goals.isEmpty
                  ? EmptyState(
                      icon: Icons.flag_rounded,
                      title: 'No goals yet',
                      message: 'Set daily, weekly, monthly or long-term goals to stay motivated.',
                      actionLabel: 'Create a goal',
                      onAction: () => _showGoalDialog(context, ref),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 380,
                        mainAxisExtent: 150,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: goals.length,
                      itemBuilder: (context, i) => _GoalCard(goal: goals[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(goal.colorValue);
    return GlassCard(
      hoverable: true,
      glowColor: color,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          ProgressRing(
            progress: goal.percent,
            size: 84,
            strokeWidth: 9,
            gradient: LinearGradient(colors: [color, AppColors.secondary]),
            center: Text('${(goal.percent * 100).round()}%', style: AppTypography.numeric(16)),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.alpha(color, 0.16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(goal.type.label,
                          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    if (goal.isComplete)
                      Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Text(goal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text('${goal.progress} / ${goal.target}',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _miniBtn(Icons.remove_rounded, () => ref.read(goalsProvider.notifier).increment(goal.id, -1)),
                    const SizedBox(width: 8),
                    _miniBtn(Icons.add_rounded, () => ref.read(goalsProvider.notifier).increment(goal.id, 1)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => ref.read(goalsProvider.notifier).delete(goal.id),
                      child: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 16, color: AppColors.text),
        ),
      );
}

void _showGoalDialog(BuildContext context, WidgetRef ref) {
  final titleCtrl = TextEditingController();
  var type = GoalType.weekly;
  var target = 7;

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New goal', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'Goal title, e.g. Run 30 km this week'),
                ),
                const SizedBox(height: 16),
                Text('Type', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final t in GoalType.values)
                      ChoiceChip(
                        label: Text(t.label),
                        selected: type == t,
                        onSelected: (_) => setState(() => type = t),
                        selectedColor: AppColors.alpha(AppColors.primary, 0.2),
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(color: type == t ? AppColors.primary : AppColors.muted, fontSize: 12),
                        shape: StadiumBorder(side: BorderSide(color: type == t ? AppColors.primary : AppColors.border)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Target', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setState(() => target = (target - 1).clamp(1, 999)),
                      icon: Icon(Icons.remove_circle_outline_rounded, color: AppColors.muted),
                    ),
                    Text('$target', style: AppTypography.numeric(18)),
                    IconButton(
                      onPressed: () => setState(() => target = (target + 1).clamp(1, 999)),
                      icon: Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GlowButton(label: 'Cancel', variant: GlowButtonVariant.outline, onPressed: () => Navigator.pop(context)),
                    const SizedBox(width: 12),
                    GlowButton(
                      label: 'Create',
                      icon: Icons.check_rounded,
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) return;
                        ref.read(goalsProvider.notifier).create(
                              title: titleCtrl.text.trim(),
                              type: type,
                              target: target,
                            );
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
