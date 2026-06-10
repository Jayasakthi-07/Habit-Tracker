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
  // Pushes are chained per id so rapid successive edits (e.g. toggling a habit
  // twice quickly) reach the server in order — otherwise an earlier upsert can
  // land after a later one and the cloud ends up holding stale state.
  final Map<String, Future<void>> _pushChain = {};
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
        final incoming = jsonEncode(data);
        final local = _box.containsKey(id) ? jsonEncode(_mapOf(id)) : null;
        if (incoming == local) {
          // Already identical — just record the shadow, no write & no UI churn.
          _shadow[id] = incoming;
        } else {
          await _applyPut(id, data);
          applied = true;
        }
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
        _enqueue(key, () => _pushPut(key, data));
      }
    }
    // Wait for the queue to drain so callers can rely on "flushed" semantics.
    await Future.wait(_pushChain.values.toList());
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
      _enqueue(id, () => _pushDelete(id));
    } else {
      final data = _mapOf(id);
      if (_shadow[id] == jsonEncode(data)) return; // echo / no real change
      _enqueue(id, () => _pushPut(id, data));
    }
  }

  /// Chains [op] after any in-flight push for the same id, so per-record
  /// writes hit the server strictly in the order they happened locally.
  void _enqueue(String id, Future<void> Function() op) {
    final prev = _pushChain[id] ?? Future<void>.value();
    late final Future<void> next;
    next = prev.then((_) => op()).whenComplete(() {
      if (_pushChain[id] == next) _pushChain.remove(id);
    });
    _pushChain[id] = next;
  }

  /// True when the local box holds a change that hasn't been pushed yet (or a
  /// pending local delete). While dirty, the local value must win over any
  /// incoming realtime event — our queued push will overwrite the cloud anyway.
  bool _isLocallyDirty(String id) {
    if (!_box.containsKey(id)) return _shadow.containsKey(id); // pending delete
    return _shadow[id] != jsonEncode(_mapOf(id));
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
      if (!_box.containsKey(id)) return;
      // A fresher local edit is in flight — let our push win, don't delete.
      if (_isLocallyDirty(id)) return;
      await _applyDelete(id);
      onRemoteApplied?.call(entity);
      return;
    }
    final data = (rec['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final incoming = jsonEncode(data);
    final local = _box.containsKey(id) ? jsonEncode(_mapOf(id)) : null;
    if (incoming == local) {
      // Same content as local (our echo, or convergent edit): record + skip.
      _shadow[id] = incoming;
      return;
    }
    // CRITICAL: while a local change is unpushed/in flight, an arriving echo of
    // an *older* push must not stomp it — that's the "tap reverts itself" bug.
    if (_isLocallyDirty(id)) return;
    await _applyPut(id, data);
    onRemoteApplied?.call(entity);
  }
}
