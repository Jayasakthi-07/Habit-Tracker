import 'package:aura_core/aura_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/storage/hive_service.dart';
import 'core/window/window_service.dart';
import 'features/notifications/notification_service.dart';

/// Application entry point.
///
/// Bootstraps local storage, the desktop window and notifications before
/// rendering the Riverpod-scoped widget tree.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();
  // Initializes the Supabase client only if SUPABASE_URL/ANON_KEY were provided
  // via --dart-define; otherwise this is a safe no-op (pure offline mode).
  await AuraSupabase.init();
  await WindowService.init();
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: AuraApp()));

  // Tray is set up after the window handle is ready.
  await WindowService.initTray();
}
