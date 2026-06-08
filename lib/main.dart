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
  await WindowService.init();
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: AuraApp()));

  // Tray is set up after the window handle is ready.
  await WindowService.initTray();
}
