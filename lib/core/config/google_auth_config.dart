/// Google OAuth 2.0 configuration for the desktop "installed app" loopback flow.
///
/// Values are injected at build time via `--dart-define` (kept out of source):
///
/// ```
/// --dart-define=GOOGLE_DESKTOP_CLIENT_ID=<new desktop client id>
/// --dart-define=GOOGLE_DESKTOP_CLIENT_SECRET=<its secret>
/// ```
///
/// The Windows app uses these to obtain a Google **id_token** via the loopback
/// flow, which is then exchanged for a Supabase session
/// (`AuthService.signInWithGoogleIdToken`). The desktop client id must also be
/// listed in Supabase → Auth → Google → "Authorized Client IDs".
abstract class GoogleAuthConfig {
  static const String clientId =
      String.fromEnvironment('GOOGLE_DESKTOP_CLIENT_ID');

  static const String clientSecret =
      String.fromEnvironment('GOOGLE_DESKTOP_CLIENT_SECRET');

  /// True when both values were provided at build time.
  static bool get isConfigured => clientId.isNotEmpty && clientSecret.isNotEmpty;

  /// OpenID Connect scopes needed to read the user's basic profile + email.
  static const List<String> scopes = ['openid', 'email', 'profile'];

  /// OIDC userinfo endpoint used to fetch the signed-in user's profile.
  static const String userInfoEndpoint =
      'https://openidconnect.googleapis.com/v1/userinfo';
}
