import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/sync/sync_controller.dart';

/// Root widget. Hosts the routed [MaterialApp] with the global dark theme.
class AuraApp extends ConsumerWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Keep cloud sync alive for the whole session; it self-gates on auth state.
    ref.watch(syncControllerProvider);
    return MaterialApp.router(
      title: 'Aura Habits',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
      builder: (context, child) {
        // Lock text scaling for a consistent desktop layout.
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}
