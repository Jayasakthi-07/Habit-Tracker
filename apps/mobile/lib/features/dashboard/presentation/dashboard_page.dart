import 'dart:math' as math;

import 'package:aura_core/aura_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_x.dart';
import '../../ai/presentation/ai_coach_page.dart';
import '../../auth/auth_provider.dart';
import '../../calendar/presentation/calendar_page.dart';
import '../../goals/presentation/goals_page.dart';
import '../../habits/presentation/providers/habit_providers.dart';
import '../../habits/presentation/widgets/habit_card.dart';
import '../../sync/sync_controller.dart';

/// The "Today" tab: greeting, week strip, gradient hero and today's habits.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  static void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: AppColors.alpha(AppColors.text, 0.05),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.muted, size: 19),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(habitsControllerProvider); // refresh on any mutation
    final repo = ref.read(habitRepositoryProvider);
    final progress = repo.todayProgress();
    final week = repo.heatmapIntensities(days: 6);
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${greeting()},',
                            style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          profile?.name.split(' ').first ?? 'there',
                          style:
                              Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  _headerIcon(Icons.auto_awesome_outlined,
                      () => _push(context, const AiCoachPage())),
                  _headerIcon(Icons.flag_outlined,
                      () => _push(context, const GoalsPage())),
                  _headerIcon(Icons.calendar_month_outlined,
                      () => _push(context, const CalendarPage(standalone: true))),
                  const SizedBox(width: 8),
                  const _SyncChip(),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: _WeekStrip(week: week, today: today),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _HeroCard(
                ratio: ratio,
                completed: progress.completed.round(),
                total: progress.total,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text('Today',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  Text(
                    '${progress.completed.round()}/${progress.total}',
                    style: AppTypography.numeric(14,
                        color: AppColors.muted, weight: FontWeight.w600),
                  ),
                ],
              ),
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
                    style: TextStyle(
                        color: AppColors.muted, fontSize: 14, height: 1.5),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
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

/// Last seven days at a glance: weekday initial + a fill that deepens with
/// that day's completion. Today is ringed with the accent.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.week, required this.today});
  final Map<DateTime, double> week;
  final DateTime today;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 6; i >= 0; i--) _day(today.subtract(Duration(days: i))),
      ],
    );
  }

  Widget _day(DateTime day) {
    final intensity = (week[day] ?? 0).clamp(0.0, 1.0);
    final isToday = day == today;
    final filled = intensity > 0;
    return Column(
      children: [
        Text(_letters[day.weekday - 1],
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isToday ? AppColors.primary : AppColors.faint)),
        const SizedBox(height: 6),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? AppColors.alpha(
                    AppColors.primary, 0.15 + 0.55 * intensity)
                : AppColors.alpha(AppColors.text, 0.04),
            border: Border.all(
              color: isToday
                  ? AppColors.primary
                  : (filled ? Colors.transparent : AppColors.border),
              width: isToday ? 1.6 : 1,
            ),
          ),
          child: Center(
            child: intensity >= 1
                ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
                : Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          isToday ? FontWeight.w700 : FontWeight.w500,
                      color: intensity > 0.45
                          ? Colors.white
                          : (isToday ? AppColors.primary : AppColors.muted),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// The aurora hero: a saturated indigo→violet gradient card with the daily
/// progress ring. Identical brand moment in both themes.
class _HeroCard extends StatelessWidget {
  const _HeroCard(
      {required this.ratio, required this.completed, required this.total});
  final double ratio;
  final int completed;
  final int total;

  String get _line {
    if (total == 0) return 'Add a habit to begin your streak';
    if (ratio >= 1) return 'Perfect day — every habit done';
    if (ratio >= 0.5) return 'Great pace, keep it going';
    if (completed > 0) return 'Good start — momentum builds';
    return 'Your day is a blank canvas';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (ratio * 100).round();
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.auroraGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppShadows.accent,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Stack(
          children: [
            // Soft light blooms for depth.
            Positioned(top: -50, right: -30, child: _bloom(150, 0.16)),
            Positioned(bottom: -60, left: -20, child: _bloom(170, 0.10)),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  SizedBox(
                    width: 88,
                    height: 88,
                    child: _Ring(ratio: ratio),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$pct%',
                            style: AppTypography.numeric(36,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                          total == 0
                              ? 'No habits scheduled'
                              : '$completed of $total completed today',
                          style: const TextStyle(
                              color: Color(0xE6FFFFFF),
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _line,
                          style: const TextStyle(
                              color: Color(0xB3FFFFFF), fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bloom(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            Colors.white.withValues(alpha: alpha),
            Colors.white.withValues(alpha: 0),
          ]),
        ),
      );
}

class _Ring extends StatelessWidget {
  const _Ring({required this.ratio});
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
      duration: AppSpacing.slow,
      curve: AppSpacing.ease,
      builder: (context, value, _) => CustomPaint(
        painter: _RingPainter(value),
        child: Center(
          child: Icon(
            ratio >= 1 ? Icons.check_rounded : Icons.bolt_rounded,
            color: Colors.white,
            size: 30,
          ),
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
      ..strokeWidth = 8
      ..color = Colors.white.withValues(alpha: 0.22);
    canvas.drawCircle(center, radius, track);

    if (ratio <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
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
    final (icon, color) = switch (status) {
      SyncStatus.syncing => (Icons.sync_rounded, AppColors.tertiary),
      SyncStatus.offline => (Icons.cloud_off_rounded, AppColors.muted),
      SyncStatus.idle => (Icons.cloud_done_rounded, AppColors.primary),
    };
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.alpha(color, 0.10),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.alpha(color, 0.25)),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
