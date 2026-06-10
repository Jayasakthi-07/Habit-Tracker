import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_x.dart';

/// A GitHub-style contribution heatmap. [intensities] maps a date (normalised
/// to midnight) to a 0..1 completion intensity for that day. Scrolls
/// horizontally and starts at the most recent week.
class HeatmapCalendar extends StatelessWidget {
  const HeatmapCalendar({
    super.key,
    required this.intensities,
    this.weeks = 26,
    this.cell = 15,
    this.baseColor,
  });

  final Map<DateTime, double> intensities;
  final int weeks;
  final double cell;
  final Color? baseColor;
  Color get _base => baseColor ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().dateOnly;
    final startMonday =
        today.subtract(Duration(days: today.weekday - 1 + (weeks - 1) * 7));

    final columns = <Widget>[];
    for (var w = 0; w < weeks; w++) {
      final days = <Widget>[];
      for (var d = 0; d < 7; d++) {
        final date = startMonday.add(Duration(days: w * 7 + d));
        final future = date.isAfter(today);
        final intensity = intensities[date] ?? 0;
        days.add(_cell(date, intensity, future));
      }
      columns.add(Column(children: days));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns,
      ),
    );
  }

  Widget _cell(DateTime date, double intensity, bool future) {
    final Color color;
    if (future || !intensities.containsKey(date)) {
      color = AppColors.alpha(AppColors.text, 0.025);
    } else if (intensity <= 0) {
      color = AppColors.alpha(AppColors.text, 0.06);
    } else {
      color = AppColors.alpha(_base, 0.25 + 0.75 * intensity.clamp(0, 1));
    }
    return Container(
      width: cell,
      height: cell,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
