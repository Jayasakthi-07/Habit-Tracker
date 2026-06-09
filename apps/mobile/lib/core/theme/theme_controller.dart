import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/hive_service.dart';

/// Persists the user's theme choice (system / light / dark) in the settings box
/// and exposes it as [ThemeMode]. The app watches this and rebuilds with the
/// matching [AppColors] brightness.
class ThemeController extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() => _read();

  static ThemeMode _read() {
    final v = HiveService.dynBox(Boxes.settings).get(_key) as String?;
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void setMode(ThemeMode mode) {
    HiveService.dynBox(Boxes.settings).put(_key, mode.name);
    state = mode;
  }

  /// The brightness this mode resolves to right now, given the [platform].
  static Brightness brightnessFor(ThemeMode mode, Brightness platform) =>
      switch (mode) {
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
        ThemeMode.system => platform,
      };
}

final themeModeProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
