import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_provider.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/shell/home_shell.dart';

/// Routes for the mobile app. The redirect gates everything behind an account
/// (no guest mode): signed-out users are sent to `/login`; signed-in users on
/// the login screen are bounced to the dashboard.
final routerProvider = Provider<GoRouter>((ref) {
  // Bridge the auth provider into a Listenable so GoRouter re-evaluates its
  // redirect whenever sign-in/out happens.
  final refresh = ValueNotifier<int>(0);
  ref.listen<UserProfile?>(authProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(authProvider) != null;
      final atLogin = state.matchedLocation == '/login';
      if (!signedIn) return atLogin ? null : '/login';
      if (atLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/', builder: (_, _) => const HomeShell()),
    ],
  );
});
