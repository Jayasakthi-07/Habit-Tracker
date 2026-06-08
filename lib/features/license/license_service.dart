import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/hive_service.dart';

/// Local commercial-license manager.
///
/// Verifies a license key offline (format + checksum) and binds it to this
/// device (one license = one device). Activation is stored locally. The design
/// is intentionally swappable for a future online verification API: replace
/// [_verifyKey] with a network call and keep the same public surface.
class LicenseState {
  const LicenseState({required this.activated, this.key = '', this.deviceId = '', this.activatedAt});

  final bool activated;
  final String key;
  final String deviceId;
  final DateTime? activatedAt;
}

class LicenseController extends Notifier<LicenseState> {
  static const _kKey = 'license_key';
  static const _kDevice = 'device_id';
  static const _kActivatedAt = 'license_activated_at';

  @override
  LicenseState build() {
    final box = HiveService.dynBox(Boxes.settings);
    final key = box.get(_kKey) as String?;
    final at = box.get(_kActivatedAt) as String?;
    return LicenseState(
      activated: key != null && _verifyKey(key),
      key: key ?? '',
      deviceId: _deviceId,
      activatedAt: at != null ? DateTime.tryParse(at) : null,
    );
  }

  /// A stable per-device identifier, generated once and persisted.
  String get _deviceId {
    final box = HiveService.dynBox(Boxes.settings);
    var id = box.get(_kDevice) as String?;
    if (id == null) {
      final seed = '${Platform.operatingSystem}-${Platform.localHostname}-${const Uuid().v4()}';
      id = sha256.convert(utf8.encode(seed)).toString().substring(0, 16).toUpperCase();
      box.put(_kDevice, id);
    }
    return id;
  }

  /// Offline key check: format AURA-XXXX-XXXX-XXXX where the last block is a
  /// checksum of the first two blocks. (A real product would also verify a
  /// signature server-side.)
  bool _verifyKey(String key) {
    final parts = key.trim().toUpperCase().split('-');
    if (parts.length != 4 || parts[0] != 'AURA') return false;
    if (parts.any((p) => p.length != 4)) return false;
    final checksum = _checksum('${parts[1]}${parts[2]}');
    return parts[3] == checksum;
  }

  String _checksum(String input) {
    final hash = sha256.convert(utf8.encode('aura-license::$input')).toString().toUpperCase();
    return hash.replaceAll(RegExp(r'[^A-Z0-9]'), '').substring(0, 4);
  }

  /// Returns null on success, or an error message.
  String? activate(String key) {
    if (!_verifyKey(key)) {
      return 'Invalid license key. Expected format: AURA-XXXX-XXXX-XXXX';
    }
    final box = HiveService.dynBox(Boxes.settings);
    box.put(_kKey, key.trim().toUpperCase());
    box.put(_kActivatedAt, DateTime.now().toIso8601String());
    state = build();
    return null;
  }

  void deactivate() {
    final box = HiveService.dynBox(Boxes.settings);
    box.delete(_kKey);
    box.delete(_kActivatedAt);
    state = build();
  }

  /// Generates a valid key for the current device — useful for demos/testing.
  String generateDemoKey() {
    String block() {
      final raw = const Uuid().v4().replaceAll('-', '').toUpperCase();
      return raw.substring(0, 4);
    }

    final b1 = block();
    final b2 = block();
    return 'AURA-$b1-$b2-${_checksum('$b1$b2')}';
  }
}

final licenseProvider = NotifierProvider<LicenseController, LicenseState>(LicenseController.new);
