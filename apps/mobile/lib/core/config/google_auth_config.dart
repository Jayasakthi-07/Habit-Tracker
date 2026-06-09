/// Google sign-in configuration for Android.
///
/// On Android, `google_sign_in` returns a Supabase-usable **id_token** only when
/// it is given the **Web** OAuth client id as its `serverClientId` (the Android
/// OAuth client itself is matched implicitly via the app's package name + SHA-1
/// fingerprint registered in Google Cloud). Both are injected at build time via
/// `--dart-define-from-file=env.json` so no secrets are committed.
///
/// Until the user completes the Google Cloud + Supabase setup (see
/// `apps/mobile/ANDROID_GOOGLE_AUTH_SETUP.md`), this stays unconfigured and the
/// login screen falls back to email-only — exactly like the desktop did before
/// its Google client existed.
abstract class GoogleAuthConfig {
  /// The **Web** OAuth client id (…apps.googleusercontent.com). Passed to
  /// `GoogleSignIn(serverClientId: …)` so Google issues an id_token aimed at it.
  static const String webClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static bool get isConfigured => webClientId.isNotEmpty;
}
