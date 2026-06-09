import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/sync/sync_controller.dart';

/// Root widget: a routed [MaterialApp] whose brightness follows the user's
/// theme choice. Because [AppColors] resolves surface/text colors from a global
/// brightness, we build a single theme and rebuild on change (including live
/// system light/dark switches via [WidgetsBindingObserver]).
class AuraApp extends ConsumerStatefulWidget {
  const AuraApp({super.key});

  @override
  ConsumerState<AuraApp> createState() => _AuraAppState();
}

class _AuraAppState extends ConsumerState<AuraApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {}); // re-resolve when the OS switches light/dark (system mode)
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(syncControllerProvider); // keep sync alive
    final mode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    final platform =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final brightness = ThemeController.brightnessFor(mode, platform);
    AppColors.brightness = brightness; // resolve tokens before the tree builds

    return MaterialApp.router(
      title: 'Aura Habits',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeFor(brightness),
      routerConfig: router,
    );
  }
}
