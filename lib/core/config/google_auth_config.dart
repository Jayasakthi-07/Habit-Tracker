/// Google OAuth 2.0 configuration for the desktop "installed app" flow.
///
/// For a **Desktop** OAuth client, Google does not treat the client secret as
/// confidential — it is expected to ship inside the distributed application and
/// is safe to embed here. Sign-in uses the loopback redirect (`http://localhost`)
/// authorization-code flow, which is the supported pattern for native desktop
/// apps (the `google_sign_in` plugin does not support Windows).
///
/// To use a different Google Cloud project, replace these two values (or load
/// them from a bundled JSON at runtime).
abstract class GoogleAuthConfig {
  static const String clientId =
      'YOUR_GOOGLE_CLIENT_ID_HERE';

  static const String clientSecret = 'YOUR_GOOGLE_CLIENT_SECRET_HERE';

  /// OpenID Connect scopes needed to read the user's basic profile + email.
  static const List<String> scopes = ['openid', 'email', 'profile'];

  /// OIDC userinfo endpoint used to fetch the signed-in user's profile.
  static const String userInfoEndpoint =
      'https://openidconnect.googleapis.com/v1/userinfo';
}
