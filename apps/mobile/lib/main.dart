import 'package:aura_core/aura_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/storage/hive_service.dart';

/// Android entry point.
///
/// Bootstraps local storage and the Supabase client (reading SUPABASE_URL /
/// SUPABASE_ANON_KEY from `--dart-define-from-file=env.json`) before rendering
/// the Riverpod-scoped widget tree. Mirrors the Windows app's bootstrap minus
/// the desktop-only window/tray setup.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();
  // No-op if credentials weren't provided (pure offline mode).
  await AuraSupabase.init();
  assert(() {
    debugPrint('[Aura] Supabase configured=${SupabaseConfig.isConfigured} '
        'ready=${AuraSupabase.isReady}');
    return true;
  }());

  runApp(const ProviderScope(child: AuraApp()));
}
