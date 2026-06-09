import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Thin wrapper around Supabase initialization and client access.
///
/// Safe to call [init] unconditionally at startup: if no Supabase credentials
/// were provided (see [SupabaseConfig]), initialization is skipped and the app
/// continues in offline/guest mode without errors.
abstract class AuraSupabase {
  static bool _initialized = false;

  /// Whether the Supabase client has been initialized and is usable.
  static bool get isReady => _initialized;

  /// Initializes Supabase if (and only if) credentials are configured.
  static Future<void> init() async {
    if (_initialized || !SupabaseConfig.isConfigured) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // The classic "anon public" key (eyJ...) is what the setup guide collects;
      // it still works and is the simplest for users to find.
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _initialized = true;
  }

  /// The active Supabase client. Throws if accessed before a successful [init];
  /// guard with [isReady] when cloud features are optional.
  static SupabaseClient get client => Supabase.instance.client;

  /// Convenience accessor for the currently signed-in user (null if none).
  static User? get currentUser => isReady ? client.auth.currentUser : null;
}
