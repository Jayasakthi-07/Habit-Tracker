import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/analytics/presentation/analytics_page.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/calendar/presentation/calendar_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/focus/presentation/focus_page.dart';
import '../../features/gamification/presentation/achievements_page.dart';
import '../../features/goals/presentation/goals_page.dart';
import '../../features/habits/presentation/habits_page.dart';
import '../../features/journal/presentation/journal_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/shell/app_shell.dart';
import 'route_names.dart';

/// Builds the app's [GoRouter], wiring auth-aware redirects and premium
/// fade/scale page transitions inside the persistent [AppShell].
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.dashboard,
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(authProvider) != null;
      final atLogin = state.matchedLocation == Routes.login;
      if (!signedIn) return atLogin ? null : Routes.login;
      if (atLogin) return Routes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        pageBuilder: (c, s) => _fade(s, const LoginPage()),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: Routes.dashboard, pageBuilder: (c, s) => _fade(s, const DashboardPage())),
          GoRoute(path: Routes.habits, pageBuilder: (c, s) => _fade(s, const HabitsPage())),
          GoRoute(path: Routes.calendar, pageBuilder: (c, s) => _fade(s, const CalendarPage())),
          GoRoute(path: Routes.analytics, pageBuilder: (c, s) => _fade(s, const AnalyticsPage())),
          GoRoute(path: Routes.goals, pageBuilder: (c, s) => _fade(s, const GoalsPage())),
          GoRoute(path: Routes.journal, pageBuilder: (c, s) => _fade(s, const JournalPage())),
          GoRoute(path: Routes.achievements, pageBuilder: (c, s) => _fade(s, const AchievementsPage())),
          GoRoute(path: Routes.focus, pageBuilder: (c, s) => _fade(s, const FocusPage())),
          GoRoute(path: Routes.settings, pageBuilder: (c, s) => _fade(s, const SettingsPage())),
        ],
      ),
    ],
  );
});

/// Builds a page whose enter/exit uses Material's fade-through motion.
///
/// Fade-through fully fades (and gently scales) the *outgoing* page out before
/// fading the *incoming* page in, so the two pages never overlap or ghost —
/// the recommended, ultra-smooth transition for switching between unrelated
/// navigation destinations like a sidebar rail.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 420),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeThroughTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        fillColor: Colors.transparent,
        child: child,
      );
    },
  );
}
