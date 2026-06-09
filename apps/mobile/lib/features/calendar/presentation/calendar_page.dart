import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_x.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../habits/presentation/providers/habit_providers.dart';
import '../../habits/presentation/widgets/habit_card.dart';

/// A month calendar coloured by daily completion intensity, with a list of the
/// selected day's scheduled habits below.
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key, this.standalone = false});

  /// When true the page is a pushed route (own Scaffold + AppBar + back button)
  /// rather than a bottom-nav tab.
  final bool standalone;

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().dateOnly;
    _month = DateTime(now.year, now.month);
    _selected = now;
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(habitsControllerProvider); // refresh on changes
    final repo = ref.read(habitRepositoryProvider);
    final intensities = repo.heatmapIntensities(days: 366);

    final selectedHabits = ref
        .read(habitRepositoryProvider)
        .getHabits()
        .where((h) => h.isScheduledOn(_selected))
        .toList();

    final body = SafeArea(
      bottom: false,
      top: !widget.standalone,
      child: CustomScrollView(
        slivers: [
          if (!widget.standalone)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Calendar',
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _monthHeader(),
                    const SizedBox(height: 12),
                    _weekdayLabels(),
                    const SizedBox(height: 8),
                    _grid(intensities),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(_selected.pretty,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          if (selectedHabits.isEmpty)
            SliverToBoxAdapter(
              child: const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Center(
                  child: Text('No habits scheduled this day.',
                      style: TextStyle(color: AppColors.muted)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
              sliver: SliverList.builder(
                itemCount: selectedHabits.length,
                itemBuilder: (_, i) =>
                    HabitCard(habit: selectedHabits[i], date: _selected),
              ),
            ),
        ],
      ),
    );

    if (!widget.standalone) return body;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Calendar'),
        elevation: 0,
      ),
      body: body,
    );
  }

  Widget _monthHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => _shiftMonth(-1),
          icon: const Icon(Icons.chevron_left_rounded),
          color: AppColors.muted,
        ),
        Expanded(
          child: Text(
            _month.monthLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text),
          ),
        ),
        IconButton(
          onPressed: () => _shiftMonth(1),
          icon: const Icon(Icons.chevron_right_rounded),
          color: AppColors.muted,
        ),
      ],
    );
  }

  Widget _weekdayLabels() {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: labels
          .map((l) => Expanded(
                child: Center(
                  child: Text(l,
                      style: const TextStyle(
                          color: AppColors.faint,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ))
          .toList(),
    );
  }

  Widget _grid(Map<DateTime, double> intensities) {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = _month.daysInMonth;
    final leading = first.weekday - 1; // Monday=0
    final today = DateTime.now().dateOnly;

    final cells = <Widget>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_month.year, _month.month, day);
      final intensity = intensities[date] ?? 0;
      final isSelected = date.isSameDay(_selected);
      final isToday = date.isSameDay(today);
      cells.add(_dayCell(date, intensity, isSelected, isToday));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: cells,
    );
  }

  Widget _dayCell(
      DateTime date, double intensity, bool isSelected, bool isToday) {
    final hasData = intensity > 0;
    return GestureDetector(
      onTap: () => setState(() => _selected = date),
      child: Container(
        decoration: BoxDecoration(
          color: hasData
              ? AppColors.alpha(AppColors.primary, 0.12 + intensity * 0.5)
              : AppColors.alpha(Colors.white, 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isToday ? AppColors.borderStrong : Colors.transparent),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              color: hasData && intensity > 0.5
                  ? const Color(0xFF002417)
                  : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
