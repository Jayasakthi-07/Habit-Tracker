import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_x.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glow_button.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../../../shared/widgets/heatmap_calendar.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../auth/auth_provider.dart';
import '../../gamification/achievements.dart';
import '../../gamification/gamification_provider.dart';
import '../../habits/presentation/providers/habit_providers.dart';
import '../../habits/presentation/widgets/habit_card.dart';
import '../../habits/presentation/widgets/habit_editor.dart';
import '../dashboard_providers.dart';
import 'widgets/weekly_chart.dart';

/// The premium analytics-center dashboard — the app's home screen.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final metrics = ref.watch(dashboardMetricsProvider);
    final game = ref.watch(gameProfileProvider);
    final today = ref.watch(todayHabitsProvider);

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Welcome(name: user?.name ?? 'there'),
          const SizedBox(height: 24),
          // Top row: hero ring + stat grid.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 4, child: _TodayHero(metrics: metrics)),
                const SizedBox(width: 16),
                // A height-matched 2x2 grid built from Rows/Expanded instead of
                // a scrollable GridView. This avoids the viewport clipping that
                // hid hovered cards and cut the bottom row in half.
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                icon: Icons.local_fire_department_rounded,
                                label: 'Current best streak',
                                value: metrics.currentBestStreak,
                                suffix: 'd',
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: StatCard(
                                icon: Icons.emoji_events_rounded,
                                label: 'All-time best streak',
                                value: metrics.bestStreak,
                                suffix: 'd',
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                icon: Icons.bolt_rounded,
                                label: 'Total XP',
                                value: game.xp,
                                color: AppColors.primary,
                                caption: 'Lvl ${game.level}',
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: StatCard(
                                icon: Icons.task_alt_rounded,
                                label: 'Completions',
                                value: metrics.totalCompleted,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
          const SizedBox(height: 24),
          _LevelBar(),
          const SizedBox(height: 24),
          // Middle row: today's habits + weekly chart.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _TodayHabits(today: today)),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: const _WeeklySummary()),
            ],
          ),
          const SizedBox(height: 24),
          // Heatmap.
          _HeatmapSection(),
          const SizedBox(height: 24),
          _AchievementsPreview(),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${greeting()}, ',
                    style: Theme.of(context).textTheme.displaySmall),
                GradientText(name,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 4),
            Text(DateTime.now().pretty, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const Spacer(),
      ],
    ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.04);
  }
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({required this.metrics});
  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final pct = (metrics.todayCompletion * 100).round();
    return GlassCard(
      glowColor: AppColors.primary,
      hoverable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's progress",
              style: TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          Center(
            child: ProgressRing(
              progress: metrics.todayCompletion,
              size: 168,
              strokeWidth: 16,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct.toDouble()),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Text('${v.round()}%', style: AppTypography.numeric(40)),
                  ),
                  Text('complete', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              metrics.todayTotal == 0
                  ? 'No habits scheduled today'
                  : '${metrics.todayDone} of ${metrics.todayTotal} habits done',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProfileProvider);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppShadows.glow(AppColors.primary, strength: 0.18),
            ),
            child: Text('${game.level}',
                style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.w800, fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Level ${game.level}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const Spacer(),
                    Text('${game.xpToNext} XP to level ${game.level + 1}',
                        style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: game.levelProgress),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 9,
                      backgroundColor: AppColors.alpha(Colors.white, 0.06),
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Row(
            children: [
              const Icon(Icons.monetization_on_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 6),
              Text('${game.coins}', style: AppTypography.numeric(18, color: AppColors.warning)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayHabits extends ConsumerWidget {
  const _TodayHabits({required this.today});
  final List today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: "Today's Habits",
            icon: Icons.today_rounded,
            trailing: GlowButton(
              label: 'Quick add',
              icon: Icons.add_rounded,
              variant: GlowButtonVariant.ghost,
              onPressed: () => showHabitEditor(context, ref),
            ),
          ),
          const SizedBox(height: 16),
          if (today.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.wb_sunny_rounded, color: AppColors.muted, size: 36),
                    const SizedBox(height: 12),
                    Text('Nothing scheduled for today.', style: TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 12),
                    GlowButton(label: 'Add a habit', icon: Icons.add_rounded, onPressed: () => showHabitEditor(context, ref)),
                  ],
                ),
              ),
            )
          else
            for (var i = 0; i < today.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HabitCard(
                  habit: today[i],
                  onEdit: () => showHabitEditor(context, ref, existing: today[i]),
                ).animate().fadeIn(delay: (40 * i).ms).slideX(begin: 0.05),
              ),
        ],
      ),
    );
  }
}

class _WeeklySummary extends ConsumerWidget {
  const _WeeklySummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bars = ref.watch(weeklyBarsProvider);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'This Week', icon: Icons.bar_chart_rounded),
          const SizedBox(height: 24),
          SizedBox(height: 180, child: WeeklyChart(values: bars)),
        ],
      ),
    );
  }
}

class _HeatmapSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(heatmapProvider);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Consistency Heatmap',
            subtitle: 'Your completion intensity over the last 6 months',
            icon: Icons.grid_view_rounded,
          ),
          const SizedBox(height: 20),
          HeatmapCalendar(intensities: data),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: TextStyle(fontSize: 11, color: AppColors.muted)),
              const SizedBox(width: 8),
              for (final o in [0.1, 0.35, 0.6, 0.85, 1.0])
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: AppColors.alpha(AppColors.primary, 0.2 + 0.8 * o),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              const SizedBox(width: 8),
              Text('More', style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _AchievementsPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Achievements',
            icon: Icons.emoji_events_rounded,
            trailing: GlowButton(
              label: 'View all',
              variant: GlowButtonVariant.ghost,
              onPressed: () => context.go(Routes.achievements),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: achievements.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final a = achievements[i];
                return Container(
                  width: 150,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: a.unlocked ? AppColors.alpha(a.color, 0.5) : AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(a.icon, color: a.unlocked ? a.color : AppColors.faint, size: 24),
                      const Spacer(),
                      Text(a.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: a.unlocked ? AppColors.text : AppColors.muted)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: a.progress,
                          minHeight: 5,
                          backgroundColor: AppColors.alpha(Colors.white, 0.06),
                          valueColor: AlwaysStoppedAnimation(a.unlocked ? a.color : AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
