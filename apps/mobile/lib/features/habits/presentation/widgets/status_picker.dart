import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/habit.dart';
import '../../domain/habit_enums.dart';

/// A premium bottom-sheet status picker for a habit on a given day.
///
/// Returns the chosen [CompletionStatus], or null if dismissed.
///
/// 🔑 Dialog-context safety (HANDOVER §8): we pop with the sheet's OWN context
/// (`sheetContext`) and return the value via the `showModalBottomSheet` future,
/// never popping a page navigator.
class StatusPicker {
  static Future<CompletionStatus?> show(
    BuildContext context, {
    required Habit habit,
    required CompletionStatus current,
  }) {
    return showModalBottomSheet<CompletionStatus>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _StatusSheet(
        habit: habit,
        current: current,
        onPick: (s) => Navigator.of(sheetContext).pop(s),
      ),
    );
  }
}

class _StatusSheet extends StatelessWidget {
  const _StatusSheet({
    required this.habit,
    required this.current,
    required this.onPick,
  });

  final Habit habit;
  final CompletionStatus current;
  final ValueChanged<CompletionStatus> onPick;

  static const _options = [
    CompletionStatus.completed,
    CompletionStatus.partial,
    CompletionStatus.skipped,
    CompletionStatus.postponed,
    CompletionStatus.pending,
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.alpha(habit.color, 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(habit.icon, color: habit.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    habit.name,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._options.map((s) => _row(s)),
          ],
        ),
      ),
    );
  }

  Widget _row(CompletionStatus s) {
    final selected = s == current;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? AppColors.alpha(s.color, 0.12)
            : AppColors.alpha(AppColors.text, 0.02),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => onPick(s),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(s.icon, color: s.color, size: 20),
                const SizedBox(width: 14),
                Text(
                  s.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? s.color : AppColors.text,
                  ),
                ),
                const Spacer(),
                if (selected)
                  Icon(Icons.check_rounded, color: s.color, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
