import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'animated_counter.dart';
import 'glass_card.dart';

/// A compact metric card with an icon, animated value and label.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.suffix = '',
    this.color = AppColors.primary,
    this.caption,
  });

  final IconData icon;
  final String label;
  final int value;
  final String suffix;
  final Color color;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      hoverable: true,
      glowColor: color,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.alpha(color, 0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const Spacer(),
              if (caption != null)
                Text(caption!, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedCounter(value: value, suffix: suffix, fontSize: 28, color: AppColors.text),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}
