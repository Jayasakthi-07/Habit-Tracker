import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../achievements.dart';
import '../gamification_provider.dart';

class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final game = ref.watch(gameProfileProvider);
    final unlocked = achievements.where((a) => a.unlocked).length;

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Achievements',
            subtitle: '$unlocked of ${achievements.length} unlocked',
            icon: Icons.emoji_events_rounded,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _MiniStat(label: 'Level', value: '${game.level}', icon: Icons.military_tech_rounded, color: AppColors.primary),
              const SizedBox(width: 14),
              _MiniStat(label: 'Total XP', value: '${game.xp}', icon: Icons.bolt_rounded, color: AppColors.secondary),
              const SizedBox(width: 14),
              _MiniStat(label: 'Coins', value: '${game.coins}', icon: Icons.monetization_on_rounded, color: AppColors.warning),
              const SizedBox(width: 14),
              _MiniStat(label: 'Unlocked', value: '$unlocked', icon: Icons.lock_open_rounded, color: AppColors.success),
            ],
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              mainAxisExtent: 150,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, i) {
              final a = achievements[i];
              return GlassCard(
                hoverable: true,
                glowColor: a.unlocked ? a.color : null,
                borderColor: a.unlocked ? AppColors.alpha(a.color, 0.4) : null,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.alpha(a.unlocked ? a.color : Colors.white, a.unlocked ? 0.16 : 0.04),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(a.unlocked ? a.icon : Icons.lock_rounded,
                              color: a.unlocked ? a.color : AppColors.faint, size: 24),
                        ),
                        const Spacer(),
                        if (a.unlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.alpha(a.color, 0.16),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text('Unlocked',
                                style: TextStyle(fontSize: 10, color: a.color, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(a.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: a.unlocked ? AppColors.text : AppColors.muted)),
                    const SizedBox(height: 4),
                    Text(a.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: a.progress,
                        minHeight: 6,
                        backgroundColor: AppColors.alpha(AppColors.text, 0.06),
                        valueColor: AlwaysStoppedAnimation(a.unlocked ? a.color : AppColors.muted),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.alpha(color, 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTypography.numeric(20)),
                Text(label, style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
