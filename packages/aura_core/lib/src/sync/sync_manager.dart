import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_engine.dart';
import 'sync_entity.dart';

enum SyncStatus { idle, syncing, offline }

/// Orchestrates a [SyncEngine] per registered box and reacts to connectivity.
///
/// Usage:
/// ```dart
/// final mgr = SyncManager(client: client, userId: uid)
///   ..register(habitsBox, SyncEntity.habits)
///   ..register(logsBox, SyncEntity.habitLogs);
/// await mgr.start();
/// mgr.remoteChanges.listen((entity) => refreshUiFor(entity));
/// ```
class SyncManager {
  SyncManager({required SupabaseClient client, required String userId})
      : _client = client,
        _userId = userId;

  final SupabaseClient _client;
  final String _userId;
  final List<SyncEngine> _engines = [];
  final StreamController<SyncEntity> _remoteChanges = StreamController<SyncEntity>.broadcast();

  /// Emits the entity type each time remote data was applied locally.
  Stream<SyncEntity> get remoteChanges => _remoteChanges.stream;

  /// Coarse status for a sync indicator in the UI.
  final ValueNotifier<SyncStatus> status = ValueNotifier(SyncStatus.idle);

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _online = true;
  bool _started = false;

  /// Register a box <-> entity pair. Call before [start].
  void register(Box box, SyncEntity entity) {
    _engines.add(SyncEngine(
      box: box,
      entity: entity,
      client: _client,
      userId: _userId,
      onRemoteApplied: (e) {
        if (!_remoteChanges.isClosed) _remoteChanges.add(e);
      },
    ));
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    status.value = SyncStatus.syncing;
    for (final e in _engines) {
      await e.start();
    }
    _connSub = Connectivity().onConnectivityChanged.listen(_onConnectivity);
    status.value = SyncStatus.idle;
  }

  Future<void> _onConnectivity(List<ConnectivityResult> result) async {
    final online = !result.contains(ConnectivityResult.none);
    if (online && !_online) {
      // Came back online — flush anything that failed while offline.
      status.value = SyncStatus.syncing;
      for (final e in _engines) {
        await e.flush();
      }
      status.value = SyncStatus.idle;
    }
    _online = online;
    if (!online) status.value = SyncStatus.offline;
  }

  Future<void> stop() async {
    _started = false;
    await _connSub?.cancel();
    _connSub = null;
    for (final e in _engines) {
      await e.stop();
    }
    _engines.clear();
    status.value = SyncStatus.idle;
    if (!_remoteChanges.isClosed) await _remoteChanges.close();
  }
}
