import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/google_auth_config.dart';

/// Raised when the native Google sign-in flow fails or is cancelled.
class GoogleAuthException implements Exception {
  GoogleAuthException(this.message);
  final String message;
  @override
  String toString() => 'GoogleAuthException: $message';
}

/// The tokens we hand to Supabase's `signInWithIdToken`.
class GoogleTokens {
  const GoogleTokens({required this.idToken, required this.accessToken});
  final String idToken;
  final String accessToken;
}

/// Android Google sign-in via the native `google_sign_in` flow.
///
/// Unlike the desktop (which runs a loopback OAuth flow), Android uses Google
/// Play Services directly. Passing the **Web** client id as `serverClientId`
/// makes Google return an `id_token` audience-scoped to that web client, which
/// is what Supabase verifies. See `aura_core/AuthService.signInWithGoogleIdToken`.
abstract class GoogleAuthService {
  static GoogleSignIn? _instance;

  static GoogleSignIn get _client => _instance ??= GoogleSignIn(
        serverClientId: GoogleAuthConfig.webClientId,
        scopes: const ['email', 'profile'],
      );

  /// Triggers the account picker and returns the Google tokens.
  /// Throws [GoogleAuthException] on cancel/failure.
  static Future<GoogleTokens> signIn() async {
    try {
      // Make sure we always show the picker rather than silently reusing a
      // stale account from a previous session.
      await _client.signOut();
      final account = await _client.signIn();
      if (account == null) {
        throw GoogleAuthException('Sign-in was cancelled.');
      }
      final auth = await account.authentication;
      final idToken = auth.idToken ?? '';
      if (idToken.isEmpty) {
        throw GoogleAuthException(
            'Google did not return an identity token. Check the Web client id.');
      }
      return GoogleTokens(idToken: idToken, accessToken: auth.accessToken ?? '');
    } on GoogleAuthException {
      rethrow;
    } catch (e) {
      throw GoogleAuthException('Google sign-in failed: $e');
    }
  }

  static Future<void> signOut() async {
    try {
      await _client.signOut();
    } catch (_) {
      // best-effort
    }
  }
}
