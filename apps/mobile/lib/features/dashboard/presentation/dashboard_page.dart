import 'dart:math' as math;

import 'package:aura_core/aura_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_x.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/auth_provider.dart';
import '../../habits/presentation/providers/habit_providers.dart';
import '../../habits/presentation/widgets/habit_card.dart';
import '../../sync/sync_controller.dart';

/// The "Today" tab: greeting, daily progress hero, and today's scheduled habits.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(habitsControllerProvider); // refresh on any mutation
    final repo = ref.read(habitRepositoryProvider);
    final progress = repo.todayProgress();
    final todays = ref.watch(todayHabitsProvider);
    final profile = ref.watch(authProvider);
    final today = DateTime.now().dateOnly;
    final ratio = progress.total == 0
        ? 0.0
        : (progress.completed / progress.total).clamp(0.0, 1.0);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${greeting()},',
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          profile?.name.split(' ').first ?? 'there',
                          style:
                              Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  const _SyncChip(),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: _HeroCard(
                ratio: ratio,
                completed: progress.completed.round(),
                total: progress.total,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text('Today',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          if (todays.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Center(
                  child: Text(
                    progress.total == 0
                        ? 'Nothing scheduled today.\nTap + to add a habit.'
                        : 'All done for today 🎉',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 14, height: 1.5),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
              sliver: SliverList.builder(
                itemCount: todays.length,
                itemBuilder: (_, i) =>
                    HabitCard(habit: todays[i], date: today),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard(
      {required this.ratio, required this.completed, required this.total});
  final double ratio;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = (ratio * 100).round();
    return GlassCard(
      padding: const EdgeInsets.all(20),
      glowColor: ratio >= 1 && total > 0 ? AppColors.primary : null,
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: _Ring(ratio: ratio),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$pct%', style: AppTypography.numeric(34)),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'No habits scheduled'
                      : '$completed of $total completed today',
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.ratio});
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RingPainter(ratio),
      child: Center(
        child: Icon(
          ratio >= 1 ? Icons.check_rounded : Icons.bolt_rounded,
          color: AppColors.primary,
          size: 28,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.ratio);
  final double ratio;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 5;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = AppColors.alpha(Colors.white, 0.08);
    canvas.drawCircle(center, radius, track);

    if (ratio <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * ratio, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.ratio != ratio;
}

/// Small live cloud-sync status chip.
class _SyncChip extends ConsumerWidget {
  const _SyncChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncControllerProvider);
    final (icon, color, _) = switch (status) {
      SyncStatus.syncing => (
          Icons.sync_rounded,
          AppColors.secondary,
          'Syncing'
        ),
      SyncStatus.offline => (
          Icons.cloud_off_rounded,
          AppColors.muted,
          'Offline'
        ),
      SyncStatus.idle => (
          Icons.cloud_done_rounded,
          AppColors.primary,
          'Synced'
        ),
    };
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.alpha(color, 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
