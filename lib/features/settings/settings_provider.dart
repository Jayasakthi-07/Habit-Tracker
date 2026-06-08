import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/hive_service.dart';

class AppSettings {
  const AppSettings({
    this.notificationsEnabled = true,
    this.minimizeToTray = true,
    this.startWithWindows = false,
    this.soundEnabled = true,
    this.weekStartsMonday = true,
  });

  final bool notificationsEnabled;
  final bool minimizeToTray;
  final bool startWithWindows;
  final bool soundEnabled;
  final bool weekStartsMonday;

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? minimizeToTray,
    bool? startWithWindows,
    bool? soundEnabled,
    bool? weekStartsMonday,
  }) =>
      AppSettings(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        minimizeToTray: minimizeToTray ?? this.minimizeToTray,
        startWithWindows: startWithWindows ?? this.startWithWindows,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        weekStartsMonday: weekStartsMonday ?? this.weekStartsMonday,
      );
}

/// Persists user-facing app settings to the settings Hive box.
class SettingsController extends Notifier<AppSettings> {
  static const _key = 'app_settings';

  @override
  AppSettings build() {
    final raw = HiveService.dynBox(Boxes.settings).get(_key);
    if (raw is Map) {
      return AppSettings(
        notificationsEnabled: raw['notificationsEnabled'] as bool? ?? true,
        minimizeToTray: raw['minimizeToTray'] as bool? ?? true,
        startWithWindows: raw['startWithWindows'] as bool? ?? false,
        soundEnabled: raw['soundEnabled'] as bool? ?? true,
        weekStartsMonday: raw['weekStartsMonday'] as bool? ?? true,
      );
    }
    return const AppSettings();
  }

  void _persist(AppSettings s) {
    HiveService.dynBox(Boxes.settings).put(_key, {
      'notificationsEnabled': s.notificationsEnabled,
      'minimizeToTray': s.minimizeToTray,
      'startWithWindows': s.startWithWindows,
      'soundEnabled': s.soundEnabled,
      'weekStartsMonday': s.weekStartsMonday,
    });
    state = s;
  }

  void setNotifications(bool v) => _persist(state.copyWith(notificationsEnabled: v));
  void setMinimizeToTray(bool v) => _persist(state.copyWith(minimizeToTray: v));
  void setStartWithWindows(bool v) => _persist(state.copyWith(startWithWindows: v));
  void setSound(bool v) => _persist(state.copyWith(soundEnabled: v));
  void setWeekStart(bool v) => _persist(state.copyWith(weekStartsMonday: v));
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
