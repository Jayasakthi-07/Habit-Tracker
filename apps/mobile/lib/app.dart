import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/sync/sync_controller.dart';

/// Root widget: a routed [MaterialApp] on the shared dark theme.
///
/// Watching [syncControllerProvider] here keeps the cloud-sync engine alive for
/// the whole app lifecycle (it starts/stops itself on auth changes), exactly
/// like the desktop's `app.dart` does.
class AuraApp extends ConsumerWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncControllerProvider); // keep sync alive
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Aura Habits',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
