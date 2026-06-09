import 'dart:async';

import 'package:aura_core/aura_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/hive_service.dart';
import '../auth/auth_provider.dart';
import '../habits/presentation/providers/habit_providers.dart';

/// The Hive boxes that mirror cloud-synced collections, in entity order.
///
/// All five collections sync bidirectionally so the phone and desktop stay in
/// lock-step. The MVP only renders habits/logs/categories; goals & journal data
/// still lands in Hive, ready for the Phase 4 screens.
const _syncedBoxes = <(String, SyncEntity)>[
  (Boxes.habits, SyncEntity.habits),
  (Boxes.logs, SyncEntity.habitLogs),
  (Boxes.categories, SyncEntity.categories),
  (Boxes.goals, SyncEntity.goals),
  (Boxes.journal, SyncEntity.journalEntries),
];

/// Key (in the profile box) tracking which account the local cache belongs to.
const _kLastSyncUser = 'last_sync_user';

/// Drives cloud sync for the Android app and enforces **per-account data
/// isolation** — a direct port of the desktop `SyncController`.
///
/// When a different account signs in than the one the local cache was last
/// synced for, the synced boxes are wiped **before** sync starts (so no
/// tombstones are pushed to the cloud) and then the new account's data is pulled
/// down. Switching back restores the original account's data from the cloud.
class SyncController extends Notifier<SyncStatus> {
  SyncManager? _manager;
  StreamSubscription<SyncEntity>? _changesSub;
  String? _currentUserId;

  @override
  SyncStatus build() {
    ref.onDispose(_teardown);
    ref.listen<UserProfile?>(authProvider, (_, next) => _handleAuth(next));
    Future.microtask(() => _handleAuth(ref.read(authProvider)));
    return SyncStatus.idle;
  }

  Future<void> _handleAuth(UserProfile? profile) async {
    final userId = AuraSupabase.isReady ? AuraSupabase.currentUser?.id : null;
    final shouldSync = profile != null && userId != null;

    if (shouldSync) {
      if (_currentUserId == userId && _manager != null) return; // already syncing
      await _teardown();
      _currentUserId = userId;
      await _start(userId);
    } else {
      await _teardown();
      _currentUserId = null;
      state = SyncStatus.idle;
    }
  }

  Future<void> _start(String userId) async {
    // Isolate accounts: if this device's cache belongs to a different user,
    // wipe it before any sync engine (and its box watcher) starts. Clearing
    // while a watcher is live would push tombstones and wipe the cloud.
    final switched = await _ensureUserScope(userId);
    if (switched) _refreshUi();

    final mgr = SyncManager(client: AuraSupabase.client, userId: userId);
    for (final (boxName, entity) in _syncedBoxes) {
      mgr.register(HiveService.box(boxName), entity);
    }
    _manager = mgr;
    mgr.status.addListener(() => state = mgr.status.value);
    _changesSub = mgr.remoteChanges.listen(_onRemoteChange);
    await mgr.start(); // reconcile pulls this account's cloud data
    _refreshUi();
  }

  /// Returns true if it wiped a previous account's local data.
  Future<bool> _ensureUserScope(String userId) async {
    final meta = HiveService.dynBox(Boxes.profile);
    final last = meta.get(_kLastSyncUser) as String?;
    var switched = false;
    if (last != null && last != userId) {
      await _clearSyncedBoxes();
      switched = true;
    }
    await meta.put(_kLastSyncUser, userId);
    return switched;
  }

  Future<void> _clearSyncedBoxes() async {
    for (final (boxName, _) in _syncedBoxes) {
      await HiveService.box(boxName).clear();
    }
    await HiveService.dynBox(Boxes.gamification).clear();
  }

  void _refreshUi() {
    ref.read(habitsControllerProvider.notifier).refreshFromStore();
  }

  void _onRemoteChange(SyncEntity entity) {
    switch (entity) {
      case SyncEntity.habits:
      case SyncEntity.habitLogs:
      case SyncEntity.categories:
        ref.read(habitsControllerProvider.notifier).refreshFromStore();
      // Goals & journal sync into Hive but have no MVP screen yet (Phase 4).
      case SyncEntity.goals:
      case SyncEntity.journalEntries:
      case SyncEntity.achievements:
      case SyncEntity.settings:
      case SyncEntity.gamification:
        break;
    }
  }

  Future<void> _teardown() async {
    await _changesSub?.cancel();
    _changesSub = null;
    final m = _manager;
    _manager = null;
    await m?.stop();
  }
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncStatus>(SyncController.new);
