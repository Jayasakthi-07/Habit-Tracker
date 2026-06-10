import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/aura_background.dart';
import '../analytics/presentation/insights_page.dart';
import '../dashboard/presentation/dashboard_page.dart';
import '../habits/presentation/habits_page.dart';
import '../habits/presentation/widgets/habit_editor_sheet.dart';
import '../journal/presentation/journal_page.dart';
import '../settings/presentation/settings_page.dart';

/// The signed-in app shell: an ambient aurora backdrop, the primary tabs, a
/// floating glass nav bar and a gradient FAB. Secondary destinations (Goals,
/// Calendar) are pushed routes reached from the dashboard header.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  // Lazily materialize tabs: heavy pages (Insights analytics) shouldn't be
  // alive — recomputing on every habit tick — before they're first visited.
  final Set<int> _built = {0};

  static const _pages = [
    DashboardPage(),
    HabitsPage(),
    InsightsPage(),
    JournalPage(),
    SettingsPage(),
  ];

  static const _tabs = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Today'),
    (Icons.check_circle_outline_rounded, Icons.check_circle_rounded, 'Habits'),
    (Icons.insights_outlined, Icons.insights_rounded, 'Insights'),
    (Icons.menu_book_outlined, Icons.menu_book_rounded, 'Journal'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _built.add(i);
      _index = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: AuraBackground(
        child: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < _pages.length; i++)
              _built.contains(i) ? _pages[i] : const SizedBox.shrink(),
          ],
        ),
      ),
      floatingActionButton: _index == 0 || _index == 1
          ? _AuraFab(onTap: () => HabitEditorSheet.show(context))
          : null,
      bottomNavigationBar: _AuraNavBar(
        index: _index,
        tabs: _tabs,
        onSelect: _select,
      ),
    );
  }
}

/// Gradient FAB with a colored shadow — the signature "add habit" action.
class _AuraFab extends StatelessWidget {
  const _AuraFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(19),
          boxShadow: AppShadows.accent,
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}

/// Floating glass navigation bar: a blurred pill with an animated active
/// indicator. Sits above the content (the scaffold extends behind it).
class _AuraNavBar extends StatelessWidget {
  const _AuraNavBar({
    required this.index,
    required this.tabs,
    required this.onSelect,
  });

  final int index;
  final List<(IconData, IconData, String)> tabs;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottomInset > 0 ? bottomInset + 2 : 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.alpha(
                  AppColors.surface, AppColors.isLight ? 0.80 : 0.74),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(child: _item(i)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int i) {
    final (icon, activeIcon, label) = tabs[i];
    final active = i == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelect(i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: AppSpacing.normal,
            curve: AppSpacing.ease,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.alpha(AppColors.primary, 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              active ? activeIcon : icon,
              size: 23,
              color: active ? AppColors.primary : AppColors.muted,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: AppSpacing.fast,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppColors.primary : AppColors.muted,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
