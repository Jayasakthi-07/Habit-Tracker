import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

/// Thin wrapper around desktop notifications.
///
/// Centralises notification setup so reminder/streak/achievement alerts share
/// one entry point. Designed so a richer scheduler can be layered on later.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb || !(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return;
    }
    try {
      await localNotifier.setup(appName: 'Aura Habits');
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  Future<void> show(String title, String body) async {
    if (!_ready) return;
    final n = LocalNotification(title: title, body: body);
    await n.show();
  }

  Future<void> reminder(String habit) =>
      show('Time for: $habit', 'Keep your streak alive — mark it done in Aura Habits.');

  Future<void> achievement(String name) =>
      show('Achievement unlocked! 🏆', name);
}
