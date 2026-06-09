import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/sync/sync_controller.dart';

/// Root widget. Hosts the routed [MaterialApp] whose brightness follows the
/// user's theme choice (system / light / dark). Because [AppColors] resolves
/// surface/text colors from a global brightness, a single theme is built and
/// the tree rebuilds on change.
class AuraApp extends ConsumerStatefulWidget {
  const AuraApp({super.key});

  @override
  ConsumerState<AuraApp> createState() => _AuraAppState();
}

class _AuraAppState extends ConsumerState<AuraApp> with WidgetsBindingObserver {
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
  void didChangePlatformBrightness() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);
    // Keep cloud sync alive for the whole session; it self-gates on auth state.
    ref.watch(syncControllerProvider);

    final platform =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final brightness = ThemeController.brightnessFor(mode, platform);
    AppColors.brightness = brightness;

    return MaterialApp.router(
      title: 'Aura Habits',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeFor(brightness),
      routerConfig: router,
      builder: (context, child) {
        // Lock text scaling for a consistent desktop layout.
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}
