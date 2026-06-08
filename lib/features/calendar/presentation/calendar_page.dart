import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_x.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../habits/domain/habit_enums.dart';
import '../../habits/presentation/providers/habit_providers.dart';
import '../../habits/presentation/widgets/habit_card.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _month = DateTime.now().startOfMonth;
  DateTime _selected = DateTime.now().dateOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Calendar',
            subtitle: 'Review and edit your habit history',
            icon: Icons.calendar_month_rounded,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _MonthGrid(
                  month: _month,
                  selected: _selected,
                  onPrev: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                  onNext: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                  onSelect: (d) => setState(() => _selected = d),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, curve: Curves.easeOutCubic)),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: _DayDetail(date: _selected)
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 400.ms)
                      .slideX(begin: 0.05, curve: Curves.easeOutCubic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends ConsumerWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.onPrev,
    required this.onNext,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(habitsControllerProvider.select((s) => s.revision));
    final repo = ref.read(habitRepositoryProvider);
    final intensities = repo.heatmapIntensities(days: 400);

    final first = month.startOfMonth;
    final leading = first.weekday - 1; // Monday-based
    final days = month.daysInMonth;
    final today = DateTime.now().dateOnly;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(month.monthLabel, style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              _navBtn(Icons.chevron_left_rounded, onPrev),
              const SizedBox(width: 8),
              _navBtn(Icons.chevron_right_rounded, onNext),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final d in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
                Expanded(
                  child: Center(
                    child: Text(d, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: leading + days,
              itemBuilder: (context, i) {
                if (i < leading) return const SizedBox();
                final dayNum = i - leading + 1;
                final date = DateTime(month.year, month.month, dayNum);
                final intensity = intensities[date] ?? 0;
                final isSelected = date.isSameDay(selected);
                final isToday = date.isSameDay(today);
                final future = date.isAfter(today);

                return GestureDetector(
                  onTap: () => onSelect(date),
                  child: AnimatedContainer(
                    duration: AppSpacing.fast,
                    decoration: BoxDecoration(
                      color: future
                          ? AppColors.alpha(Colors.white, 0.02)
                          : intensity > 0
                              ? AppColors.alpha(AppColors.primary, 0.15 + 0.5 * intensity)
                              : AppColors.alpha(Colors.white, 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : isToday
                                ? AppColors.alpha(AppColors.secondary, 0.6)
                                : Colors.transparent,
                        width: isSelected ? 1.6 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                          color: future ? AppColors.faint : AppColors.text,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 18, color: AppColors.text),
        ),
      );
}

class _DayDetail extends ConsumerWidget {
  const _DayDetail({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitsControllerProvider);
    final scheduled = state.habits.where((h) => !h.archived && h.isScheduledOn(date)).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: date.isToday ? 'Today' : date.pretty,
            subtitle: '${scheduled.length} habit${scheduled.length == 1 ? '' : 's'} scheduled',
            icon: Icons.event_note_rounded,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: scheduled.isEmpty
                ? const Center(
                    child: Text('No habits scheduled on this day.', style: TextStyle(color: AppColors.muted)))
                : ListView.separated(
                    itemCount: scheduled.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final h = scheduled[i];
                      return HabitCard(habit: h, date: date)
                          .animate()
                          .fadeIn(delay: (30 * i).ms)
                          .slideX(begin: 0.05);
                    },
                  ),
          ),
          if (scheduled.isNotEmpty) ...[
            const Divider(height: 24),
            _DaySummary(date: date, habits: scheduled),
          ],
        ],
      ),
    );
  }
}

class _DaySummary extends ConsumerWidget {
  const _DaySummary({required this.date, required this.habits});
  final DateTime date;
  final List habits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(habitRepositoryProvider);
    var done = 0;
    for (final h in habits) {
      final log = repo.logFor(h.id, date);
      if (log != null && log.status == CompletionStatus.completed) done++;
    }
    final pct = habits.isEmpty ? 0 : (done / habits.length * 100).round();
    return Row(
      children: [
        const Icon(Icons.insights_rounded, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('Completion: ', style: Theme.of(context).textTheme.bodyMedium),
        Text('$pct%  ($done/${habits.length})',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
