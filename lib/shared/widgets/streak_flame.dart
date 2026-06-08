import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Animated streak indicator — a glowing flame that pulses, paired with the
/// streak count. Brightens as the streak grows.
class StreakFlame extends StatelessWidget {
  const StreakFlame({super.key, required this.streak, this.size = 22});

  final int streak;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hot = streak >= 7;
    final color = hot ? AppColors.warning : AppColors.muted;

    final flame = Icon(Icons.local_fire_department_rounded, size: size, color: color);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (streak > 0)
          flame
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                duration: 1200.ms,
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                curve: Curves.easeInOut,
              )
              .then()
        else
          Icon(Icons.local_fire_department_outlined, size: size, color: AppColors.faint),
        const SizedBox(width: 6),
        Text(
          '$streak',
          style: AppTypography.numeric(size * 0.85, color: streak > 0 ? AppColors.text : AppColors.faint),
        ),
      ],
    );
  }
}
