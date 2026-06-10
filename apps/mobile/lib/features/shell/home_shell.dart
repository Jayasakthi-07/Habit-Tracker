import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../analytics/presentation/insights_page.dart';
import '../dashboard/presentation/dashboard_page.dart';
import '../habits/presentation/habits_page.dart';
import '../habits/presentation/widgets/habit_editor_sheet.dart';
import '../journal/presentation/journal_page.dart';
import '../settings/presentation/settings_page.dart';

/// The signed-in app shell: a bottom-nav scaffold hosting the primary tabs.
/// Secondary destinations (Goals, Calendar) are pushed routes reached from the
/// dashboard header and the Profile tab.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _pages = [
    DashboardPage(),
    HabitsPage(),
    InsightsPage(),
    JournalPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButton: _index == 0 || _index == 1
          ? FloatingActionButton(
              onPressed: () => HabitEditorSheet.show(context),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.surface.withValues(alpha: 0.96),
          indicatorColor: AppColors.alpha(AppColors.primary, 0.16),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primary : AppColors.muted,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? AppColors.primary : AppColors.muted,
              size: 24,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Today'),
            NavigationDestination(
                icon: Icon(Icons.check_circle_outline_rounded),
                selectedIcon: Icon(Icons.check_circle_rounded),
                label: 'Habits'),
            NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights_rounded),
                label: 'Insights'),
            NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'Journal'),
            NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
