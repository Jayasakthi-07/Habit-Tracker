import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/heatmap_calendar.dart';
import '../../gamification/achievements.dart';
import '../../gamification/gamification_provider.dart';
import '../../habits/presentation/providers/habit_providers.dart';
import '../../share/share_card_page.dart';
import 'analytics_providers.dart';

/// The "Insights" tab: gamification progress, headline stats, a trend chart
/// with a time-range selector, per-weekday performance, a contribution heatmap,
/// per-habit success bars, and the achievements grid — all derived live.
class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  int _range = 30; // 7 / 30 / 90 days

  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    ref.watch(habitsControllerProvider); // recompute on any change
    final repo = ref.read(habitRepositoryProvider);
    final data = ref.watch(analyticsProvider);
    final game = ref.watch(gameProfileProvider);
    final achievements = ref.watch(achievementsProvider);
    final trend = repo.completionTrend(days: _range);
    final weekday = repo.overallWeekdayPerformance();
    final heatmap = repo.heatmapIntensities();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Row(
            children: [
              Text('Insights',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.ios_share_rounded,
                    color: AppColors.muted),
                onPressed: () => ShareCardPage.open(
                  context,
                  ShareCardSpec(
                    icon: Icons.auto_graph_rounded,
                    headline: 'Level ${game.level}',
                    title: '${(data.overallSuccess * 100).round()}% success',
                    subtitle: '${data.activeDays} active days · ${game.xp} XP',
                    stats: [
                      (label: 'Level', value: '${game.level}'),
                      (label: 'XP', value: '${game.xp}'),
                      (
                        label: 'Active',
                        value: '${data.activeDays}d'
                      ),
                    ],
                    shareText:
                        'Level ${game.level} on Aura Habits — ${(data.overallSuccess * 100).round()}% habit success ✨',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LevelCard(game: game),
          const SizedBox(height: 16),
          _statGrid(data),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Trend', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              _rangeChip(7),
              const SizedBox(width: 6),
              _rangeChip(30),
              const SizedBox(width: 6),
              _rangeChip(90),
            ],
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
            child: SizedBox(height: 160, child: _TrendChart(trend)),
          ),
          const SizedBox(height: 20),
          Text('By weekday', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: [
                for (var wd = 1; wd <= 7; wd++)
                  _bar(_labels[wd - 1], weekday[wd] ?? 0, AppColors.secondary),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Activity', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 7 * 19.0,
              child: HeatmapCalendar(intensities: heatmap, weeks: 26),
            ),
          ),
          if (data.habitSuccess.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Habit success rate',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                children: [
                  for (final h in data.habitSuccess) _bar(h.name, h.rate, h.color),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text('Achievements', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _achievementsGrid(context, achievements),
        ],
      ),
    );
  }

  Widget _rangeChip(int days) {
    final sel = _range == days;
    return GestureDetector(
      onTap: () => setState(() => _range = days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel
              ? AppColors.alpha(AppColors.primary, 0.16)
              : AppColors.alpha(Colors.white, 0.03),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: sel ? AppColors.primary : AppColors.border),
        ),
        child: Text('${days}d',
            style: TextStyle(
                color: sel ? AppColors.primary : AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _statGrid(AnalyticsData d) {
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                label: 'Overall',
                value: '${(d.overallSuccess * 100).round()}%',
                icon: Icons.track_changes_rounded,
                color: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                label: 'Active days',
                value: '${d.activeDays}',
                icon: Icons.calendar_today_rounded,
                color: AppColors.secondary)),
      ],
    );
  }

  Widget _bar(String name, double rate, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.text, fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: rate,
                minHeight: 8,
                backgroundColor: AppColors.alpha(Colors.white, 0.06),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 38,
            child: Text('${(rate * 100).round()}%',
                textAlign: TextAlign.right,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _achievementsGrid(BuildContext context, List<Achievement> items) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: items
          .map((a) => _AchievementCard(
                a: a,
                onTap: a.unlocked ? () => _shareAchievement(context, a) : null,
              ))
          .toList(),
    );
  }

  void _shareAchievement(BuildContext context, Achievement a) {
    ShareCardPage.open(
      context,
      ShareCardSpec(
        icon: a.icon,
        headline: 'Unlocked!',
        title: a.title,
        subtitle: a.description,
        accent: a.color,
        shareText: 'I just unlocked "${a.title}" on Aura Habits 🏆',
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.game});
  final GameProfile game;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text('${game.level}',
                      style: const TextStyle(
                          color: Color(0xFF002417),
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Level ${game.level}',
                        style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    Text('${game.xp} XP · ${game.coins} coins',
                        style:
                            const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ),
              Text('${game.xpToNext} to next',
                  style: const TextStyle(color: AppColors.faint, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: game.levelProgress,
              minHeight: 10,
              backgroundColor: AppColors.alpha(Colors.white, 0.06),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value, style: AppTypography.numeric(24)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.a, this.onTap});
  final Achievement a;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      glowColor: a.unlocked ? a.color : null,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.alpha(a.color, a.unlocked ? 0.18 : 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(a.icon,
                    color: a.unlocked ? a.color : AppColors.faint, size: 18),
              ),
              const Spacer(),
              if (a.unlocked)
                Icon(Icons.ios_share_rounded, color: a.color, size: 15),
            ],
          ),
          const Spacer(),
          Text(a.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: a.unlocked ? AppColors.text : AppColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(a.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.faint, fontSize: 11)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: a.progress,
              minHeight: 4,
              backgroundColor: AppColors.alpha(Colors.white, 0.06),
              valueColor: AlwaysStoppedAnimation(a.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart(this.trend);
  final List<double> trend;

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return const Center(
        child: Text('No data yet', style: TextStyle(color: AppColors.muted)),
      );
    }
    final spots = <FlSpot>[
      for (var i = 0; i < trend.length; i++) FlSpot(i.toDouble(), trend[i]),
    ];
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.25,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.alpha(Colors.white, 0.05), strokeWidth: 1),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: AppColors.primary,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.alpha(AppColors.primary, 0.25),
                  AppColors.alpha(AppColors.primary, 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
