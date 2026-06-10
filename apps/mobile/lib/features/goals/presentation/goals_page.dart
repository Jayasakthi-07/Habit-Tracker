import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glow_button.dart';
import '../domain/goal.dart';
import '../goals_provider.dart';

/// Goals list with progress rings + quick increment. Pushed from the dashboard
/// and Profile. Data lives in the synced `goals` box.
class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Goals'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => GoalEditorSheet.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: goals.isEmpty
          ? _empty(context)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              itemCount: goals.length,
              itemBuilder: (_, i) => _GoalCard(goal: goals[i]),
            ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_rounded, color: AppColors.primary, size: 56),
            const SizedBox(height: 16),
            Text('No goals yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Set a target and track your progress toward it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted)),
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
    final ctrl = ref.read(goalsProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        blur: 0,
        glowColor: goal.isComplete ? color : null,
        onLongPress: () => _confirmDelete(context, ref),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: _GoalRing(percent: goal.percent, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text('${goal.type.label} · ${goal.progress}/${goal.target}',
                          style: TextStyle(
                              color: AppColors.muted, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _stepBtn(Icons.remove_rounded,
                    () => ctrl.increment(goal.id, -1), goal.progress > 0),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: goal.percent,
                      minHeight: 8,
                      backgroundColor: AppColors.alpha(Colors.white, 0.06),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _stepBtn(Icons.add_rounded,
                    () => ctrl.increment(goal.id, 1), !goal.isComplete),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap, bool enabled) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.alpha(Colors.white, enabled ? 0.06 : 0.02),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 18, color: enabled ? AppColors.text : AppColors.faint),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Delete goal?',
            style: TextStyle(color: AppColors.text)),
        content: Text(goal.title,
            style: TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child:
                Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(goalsProvider.notifier).delete(goal.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _GoalRing extends StatelessWidget {
  const _GoalRing({required this.percent, required this.color});
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GoalRingPainter(percent, color),
      child: Center(
        child: Text('${(percent * 100).round()}',
            style: AppTypography.numeric(15, color: color)),
      ),
    );
  }
}

class _GoalRingPainter extends CustomPainter {
  _GoalRingPainter(this.percent, this.color);
  final double percent;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = AppColors.alpha(Colors.white, 0.08));
    if (percent <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_GoalRingPainter old) =>
      old.percent != percent || old.color != color;
}

/// Bottom-sheet editor to create a goal.
class GoalEditorSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _GoalEditor(),
    );
  }
}

class _GoalEditor extends ConsumerStatefulWidget {
  const _GoalEditor();
  @override
  ConsumerState<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends ConsumerState<_GoalEditor> {
  final _title = TextEditingController();
  GoalType _type = GoalType.weekly;
  int _target = 7;
  int _colorValue = AppColors.habitPalette.first.toARGB32();
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give your goal a title.');
      return;
    }
    await ref.read(goalsProvider.notifier).create(
          title: title,
          type: _type,
          target: _target,
          colorValue: _colorValue,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('New goal',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 18),
              TextField(
                controller: _title,
                style: TextStyle(color: AppColors.text),
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 20),
              Text('Type',
                  style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: GoalType.values.map((t) {
                  final sel = t == _type;
                  return GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.alpha(AppColors.primary, 0.14)
                            : AppColors.alpha(Colors.white, 0.03),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                        border: Border.all(
                            color: sel ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(t.label,
                          style: TextStyle(
                              color: sel ? AppColors.primary : AppColors.muted,
                              fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Target',
                      style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  _stepBtn(Icons.remove_rounded,
                      () => setState(() => _target = math.max(1, _target - 1))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('$_target',
                        style: AppTypography.numeric(20)),
                  ),
                  _stepBtn(Icons.add_rounded,
                      () => setState(() => _target += 1)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Color',
                  style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppColors.habitPalette.map((c) {
                  final v = c.toARGB32();
                  final sel = v == _colorValue;
                  return GestureDetector(
                    onTap: () => setState(() => _colorValue = v),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: sel ? Colors.white : Colors.transparent,
                            width: 2),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!,
                    style:
                        const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
              const SizedBox(height: 22),
              GlowButton(
                label: 'Create goal',
                icon: Icons.check_rounded,
                expand: true,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.alpha(Colors.white, 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.text),
        ),
      );
}
