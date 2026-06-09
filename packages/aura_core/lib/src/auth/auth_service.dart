import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/aura_supabase.dart';

/// Supabase-backed authentication used by both desktop and mobile.
///
/// Supports:
/// - **Email + password** sign-up with a **6-digit email verification code** (OTP),
///   sign-in, resend code, and password reset.
/// - **Google** via `signInWithIdToken` — each platform obtains the Google
///   id_token its own way (desktop: loopback OAuth; Android: google_sign_in) and
///   hands it here, so the Supabase user record is created/linked centrally.
///
/// Email flows require no extra configuration beyond the Supabase project.
/// Google requires the Google provider to be enabled in Supabase (see
/// supabase/GOOGLE_AUTH_SETUP.md).
class AuthService {
  AuthService(this._client);

  /// Convenience constructor using the shared [AuraSupabase] client.
  factory AuthService.instance() => AuthService(AuraSupabase.client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  // ---- Session state ----

  Session? get currentSession => _auth.currentSession;
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  /// Emits on sign-in, sign-out, token refresh, etc.
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  // ---- Email + password ----

  /// Creates the account. Behaviour depends on the Supabase email setting:
  /// - **Confirm email ON**  → returns a user but no session; a verification
  ///   code is emailed and [verifyEmailOtp] must be called.
  /// - **Confirm email OFF** → returns a session immediately (signed in).
  ///
  /// Inspect `response.session` to tell which happened.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) {
    return _auth.signUp(
      email: email,
      password: password,
      data: fullName != null && fullName.isNotEmpty ? {'full_name': fullName} : null,
    );
  }

  /// Confirms a sign-up using the 6-digit code emailed to the user. On success a
  /// session is established and the user is signed in.
  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    return _auth.verifyOTP(email: email, token: token, type: OtpType.signup);
  }

  /// Re-sends the sign-up verification code.
  Future<void> resendSignupCode(String email) {
    return _auth.resend(type: OtpType.signup, email: email);
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  /// Sends a password-reset email.
  Future<void> sendPasswordReset(String email) {
    return _auth.resetPasswordForEmail(email);
  }

  // ---- Google (platform supplies the id_token) ----

  Future<AuthResponse> signInWithGoogleIdToken({
    required String idToken,
    String? accessToken,
    String? nonce,
  }) {
    return _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
      nonce: nonce,
    );
  }

  // ---- Sign out ----

  Future<void> signOut() => _auth.signOut();
}
