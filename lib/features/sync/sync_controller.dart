import 'dart:async';

import 'package:aura_core/aura_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/hive_service.dart';
import '../auth/auth_provider.dart';
import '../goals/goals_provider.dart';
import '../habits/presentation/providers/habit_providers.dart';
import '../journal/journal_provider.dart';

/// Drives cloud sync for the desktop app.
///
/// Starts a [SyncManager] when a real (non-guest) account is signed in and
/// Supabase is configured; tears it down on sign-out or when switching to guest.
/// Remote changes are routed back into the relevant Riverpod providers so the UI
/// updates live. Exposes the coarse [SyncStatus] as its state.
class SyncController extends Notifier<SyncStatus> {
  SyncManager? _manager;
  StreamSubscription<SyncEntity>? _changesSub;

  @override
  SyncStatus build() {
    ref.onDispose(_teardown);
    ref.listen<UserProfile?>(authProvider, (_, next) => _handleAuth(next));
    // Evaluate the current auth state once on creation.
    Future.microtask(() => _handleAuth(ref.read(authProvider)));
    return SyncStatus.idle;
  }

  Future<void> _handleAuth(UserProfile? profile) async {
    final userId = AuraSupabase.isReady ? AuraSupabase.currentUser?.id : null;
    final shouldSync = profile != null && !profile.isGuest && userId != null;
    if (shouldSync && _manager == null) {
      await _start(userId);
    } else if (!shouldSync && _manager != null) {
      await _teardown();
      state = SyncStatus.idle;
    }
  }

  Future<void> _start(String userId) async {
    final mgr = SyncManager(client: AuraSupabase.client, userId: userId);
    mgr.register(HiveService.box(Boxes.habits), SyncEntity.habits);
    mgr.register(HiveService.box(Boxes.logs), SyncEntity.habitLogs);
    mgr.register(HiveService.box(Boxes.categories), SyncEntity.categories);
    mgr.register(HiveService.box(Boxes.goals), SyncEntity.goals);
    mgr.register(HiveService.box(Boxes.journal), SyncEntity.journalEntries);
    _manager = mgr;
    mgr.status.addListener(() => state = mgr.status.value);
    _changesSub = mgr.remoteChanges.listen(_onRemoteChange);
    await mgr.start();
  }

  void _onRemoteChange(SyncEntity entity) {
    switch (entity) {
      case SyncEntity.habits:
      case SyncEntity.habitLogs:
      case SyncEntity.categories:
        ref.read(habitsControllerProvider.notifier).refreshFromStore();
      case SyncEntity.goals:
        ref.invalidate(goalsProvider);
      case SyncEntity.journalEntries:
        ref.invalidate(journalProvider);
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
