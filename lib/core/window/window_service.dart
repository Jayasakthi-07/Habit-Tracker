import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Handles desktop window chrome (frameless title bar, sizing, persistence)
/// and the Windows system tray (minimize-to-tray, quick actions).
class WindowService {
  static const _minSize = Size(1100, 720);
  static const _defaultSize = Size(1320, 860);

  /// Call before `runApp` to configure the window.
  static Future<void> init() async {
    if (!_isDesktop) return;
    await windowManager.ensureInitialized();

    const options = WindowOptions(
      size: _defaultSize,
      minimumSize: _minSize,
      center: true,
      backgroundColor: Color(0xFF0A0A0A),
      titleBarStyle: TitleBarStyle.hidden,
      title: 'Aura Habits',
    );

    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  /// Sets up the tray icon and context menu. Safe to call after the app starts.
  static Future<void> initTray() async {
    if (!_isDesktop) return;
    try {
      await trayManager.setIcon(_trayIconPath);
      await trayManager.setToolTip('Aura Habits');
      await trayManager.setContextMenu(Menu(items: [
        MenuItem(key: 'show', label: 'Open Aura Habits'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit'),
      ]));
    } catch (e) {
      debugPrint('Tray init skipped: $e');
    }
  }

  static String get _trayIconPath {
    // In a packaged build the icon ships alongside the executable.
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final packaged = '$exeDir/data/flutter_assets/assets/icons/tray.ico';
    if (File(packaged).existsSync()) return packaged;
    return 'windows/runner/resources/app_icon.ico';
  }

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  static Future<void> minimize() => windowManager.minimize();
  static Future<void> maximizeToggle() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  static Future<void> hideToTray() => windowManager.hide();
  static Future<void> restoreFromTray() async {
    await windowManager.show();
    await windowManager.focus();
  }

  static Future<void> close() => windowManager.close();
  static Future<void> startDrag() => windowManager.startDragging();
}
