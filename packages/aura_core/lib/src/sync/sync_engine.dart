import 'dart:async';
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_entity.dart';

/// Bidirectional, offline-first sync for a single Hive [Box] <-> Supabase table.
///
/// Model: the Hive **box key** is the row `id`; the box **value** (a JSON map) is
/// stored in the `data` jsonb column. Deletes are soft (a `deleted_at`
/// tombstone) so they propagate to other devices.
///
/// Echo protection uses a per-id content "shadow" (the last JSON we synced):
/// - applying a remote change records the shadow *before* writing locally, so the
///   resulting box event is recognised as an echo and not pushed back;
/// - a realtime event whose data already equals the shadow is ignored.
class SyncEngine {
  SyncEngine({
    required Box box,
    required this.entity,
    required SupabaseClient client,
    required String userId,
    this.onRemoteApplied,
  })  : _box = box,
        _client = client,
        _userId = userId;

  final Box _box;
  final SyncEntity entity;
  final SupabaseClient _client;
  final String _userId;

  /// Called (with [entity]) after one or more remote changes were applied
  /// locally, so the UI layer can refresh.
  final void Function(SyncEntity entity)? onRemoteApplied;

  final Map<String, String> _shadow = {}; // id -> last-synced json
  StreamSubscription<BoxEvent>? _boxSub;
  RealtimeChannel? _channel;
  bool _started = false;

  SupabaseQueryBuilder get _table => _client.from(entity.table);

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      await _reconcile();
    } catch (_) {
      // Offline or transient error: local watcher + reconnect flush will catch up.
    }
    _subscribeRealtime();
    _boxSub = _box.watch().listen(_onLocalChange);
  }

  Future<void> stop() async {
    _started = false;
    await _boxSub?.cancel();
    _boxSub = null;
    final ch = _channel;
    _channel = null;
    if (ch != null) await _client.removeChannel(ch);
  }

  // ---------------------------------------------------------------------------
  // Reconcile: pull cloud -> local, then push local-only records up.
  // ---------------------------------------------------------------------------
  Future<void> _reconcile() async {
    final rows = await _table.select().eq('user_id', _userId);
    final remoteIds = <String>{};
    var applied = false;
    for (final row in (rows as List).cast<Map<String, dynamic>>()) {
      final id = row['id'] as String;
      remoteIds.add(id);
      if (row['deleted_at'] != null) {
        if (_box.containsKey(id)) {
          await _applyDelete(id);
          applied = true;
        }
      } else {
        final data = (row['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
        await _applyPut(id, data);
        applied = true;
      }
    }
    // Migrate local-only records up to the cloud.
    for (final key in _box.keys.map((k) => k.toString())) {
      if (!remoteIds.contains(key)) {
        await _pushPut(key, _mapOf(key));
      }
    }
    if (applied) onRemoteApplied?.call(entity);
  }

  /// Re-push any local record whose content no longer matches its shadow
  /// (used to flush writes that failed while offline).
  Future<void> flush() async {
    for (final key in _box.keys.map((k) => k.toString())) {
      final data = _mapOf(key);
      if (_shadow[key] != jsonEncode(data)) {
        await _pushPut(key, data);
      }
    }
  }

  Map<String, dynamic> _mapOf(String key) {
    final raw = _box.get(key);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {'value': raw};
  }

  // ---------------------------------------------------------------------------
  // Apply remote -> local (shadow recorded first to suppress the echo).
  // ---------------------------------------------------------------------------
  Future<void> _applyPut(String id, Map<String, dynamic> data) async {
    _shadow[id] = jsonEncode(data);
    await _box.put(id, data);
  }

  Future<void> _applyDelete(String id) async {
    _shadow.remove(id);
    await _box.delete(id);
  }

  // ---------------------------------------------------------------------------
  // Local change -> push to cloud.
  // ---------------------------------------------------------------------------
  void _onLocalChange(BoxEvent event) {
    final id = event.key.toString();
    if (event.deleted) {
      // No shadow => never synced, or this is the echo of a remote delete.
      if (!_shadow.containsKey(id)) return;
      _pushDelete(id);
    } else {
      final data = _mapOf(id);
      if (_shadow[id] == jsonEncode(data)) return; // echo / no real change
      _pushPut(id, data);
    }
  }

  Future<void> _pushPut(String id, Map<String, dynamic> data) async {
    try {
      await _table.upsert({
        'id': id,
        'user_id': _userId,
        'data': data,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'deleted_at': null,
      });
      _shadow[id] = jsonEncode(data);
    } catch (_) {
      // Leave shadow stale so flush()/reconnect retries this record.
    }
  }

  Future<void> _pushDelete(String id) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _table.upsert({
        'id': id,
        'user_id': _userId,
        'updated_at': now,
        'deleted_at': now,
      });
      _shadow.remove(id);
    } catch (_) {
      // Retry on next flush.
    }
  }

  // ---------------------------------------------------------------------------
  // Realtime: cloud -> local.
  // ---------------------------------------------------------------------------
  void _subscribeRealtime() {
    _channel = _client.channel('sync-${entity.table}-$_userId');
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: entity.table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: _onRemoteChange,
        )
        .subscribe();
  }

  Future<void> _onRemoteChange(PostgresChangePayload payload) async {
    final rec = payload.newRecord;
    final id = rec['id'] as String?;
    if (id == null) return;
    if (rec['deleted_at'] != null) {
      if (_box.containsKey(id)) {
        await _applyDelete(id);
        onRemoteApplied?.call(entity);
      }
      return;
    }
    final data = (rec['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    if (_shadow[id] == jsonEncode(data)) return; // our own echo
    await _applyPut(id, data);
    onRemoteApplied?.call(entity);
  }
}
