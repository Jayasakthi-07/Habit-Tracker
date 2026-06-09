import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Smoothly tweens an integer value when it changes — used for XP, streaks
/// and stat numbers to give the dashboard a lively, premium feel.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.fontSize = 28,
    this.color,
    this.suffix = '',
    this.prefix = '',
    this.duration = const Duration(milliseconds: 800),
  });

  final int value;
  final double fontSize;
  final Color? color;
  final String suffix;
  final String prefix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Text(
          '$prefix${v.round()}$suffix',
          style: AppTypography.numeric(fontSize, color: color ?? AppColors.text),
        );
      },
    );
  }
}
