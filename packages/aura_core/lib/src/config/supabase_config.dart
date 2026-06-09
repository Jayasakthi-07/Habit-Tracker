/// Supabase connection configuration.
///
/// Values are injected at build/run time via `--dart-define` so no secrets are
/// committed to source control:
///
/// ```
/// flutter run   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
/// flutter build windows --release \
///               --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// ```
///
/// The **anon key** is safe to embed in a client because every table is locked
/// down by Row-Level Security (a user can only ever touch their own rows). The
/// `service_role` key must NEVER be shipped — it bypasses RLS.
abstract class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// True when both values were provided at build time. When false, the app
  /// runs in pure offline/guest mode (no cloud features), so the existing
  /// Windows experience keeps working with no Supabase project configured.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
