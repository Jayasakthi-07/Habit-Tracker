import 'dart:async';

import 'package:aura_core/aura_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/google_auth_config.dart';
import '../../core/storage/hive_service.dart';
import 'google_auth_service.dart';

/// The authenticated (or guest) user profile, surfaced to the UI.
///
/// Backed by Supabase when signed in with an account, or held locally for guest
/// / offline mode. Premium is a local flag (offline license keys).
class UserProfile {
  const UserProfile({
    required this.name,
    this.email = '',
    this.isGuest = false,
    this.isPremium = false,
    this.avatarSeed = 0,
    this.photoUrl = '',
  });

  final String name;
  final String email;
  final bool isGuest;
  final bool isPremium;
  final int avatarSeed;
  final String photoUrl;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'isGuest': isGuest,
        'isPremium': isPremium,
        'avatarSeed': avatarSeed,
        'photoUrl': photoUrl,
      };

  factory UserProfile.fromJson(Map json) => UserProfile(
        name: json['name'] as String? ?? 'User',
        email: json['email'] as String? ?? '',
        isGuest: json['isGuest'] as bool? ?? false,
        isPremium: json['isPremium'] as bool? ?? false,
        avatarSeed: json['avatarSeed'] as int? ?? 0,
        photoUrl: json['photoUrl'] as String? ?? '',
      );

  UserProfile copyWith({String? name, String? email, bool? isPremium}) => UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        isGuest: isGuest,
        isPremium: isPremium ?? this.isPremium,
        avatarSeed: avatarSeed,
        photoUrl: photoUrl,
      );
}

/// Manages the current session via Supabase (email + Google) with a local
/// guest/offline fallback. Returns `null` when nobody is signed in.
class AuthController extends Notifier<UserProfile?> {
  static const _kProfile = 'current_profile';
  static const _kRemember = 'remember_me';
  static const _kPremium = 'is_premium';
  static const _noCloud =
      'Cloud sign-in is unavailable right now. You can continue as guest.';

  AuthService? _auth;
  StreamSubscription<AuthState>? _sub;

  @override
  UserProfile? build() {
    _auth = AuraSupabase.isReady ? AuthService.instance() : null;

    if (_auth != null) {
      _sub = _auth!.onAuthStateChange.listen(_onAuthChanged);
      ref.onDispose(() => _sub?.cancel());
    }

    // A live Supabase session wins; otherwise restore a remembered local/guest
    // profile so offline use keeps working.
    final supaUser = _auth?.currentUser;
    if (supaUser != null) return _profileFromSupabase(supaUser);

    final box = HiveService.dynBox(Boxes.profile);
    final remember = box.get(_kRemember, defaultValue: false) as bool;
    final stored = box.get(_kProfile);
    if (remember && stored != null) {
      return UserProfile.fromJson(Map.from(stored as Map));
    }
    return null;
  }

  void _onAuthChanged(AuthState data) {
    final user = data.session?.user;
    if (user != null) {
      _persist(_profileFromSupabase(user), remember: true);
    } else if (data.event == AuthChangeEvent.signedOut) {
      if (state != null && !state!.isGuest) state = null;
    }
  }

  bool _premiumLocal() =>
      HiveService.dynBox(Boxes.profile).get(_kPremium, defaultValue: false) as bool;

  UserProfile _profileFromSupabase(User user) {
    final meta = user.userMetadata ?? const <String, dynamic>{};
    final name = (meta['full_name'] ??
            meta['name'] ??
            (user.email != null ? user.email!.split('@').first : null) ??
            'User')
        .toString();
    return UserProfile(
      name: name,
      email: user.email ?? '',
      photoUrl: (meta['avatar_url'] ?? meta['picture'] ?? '').toString(),
      isPremium: _premiumLocal(),
    );
  }

  void _persist(UserProfile profile, {required bool remember}) {
    final box = HiveService.dynBox(Boxes.profile);
    box.put(_kProfile, profile.toJson());
    box.put(_kRemember, remember);
    state = profile;
  }

  bool get _rememberFlag =>
      HiveService.dynBox(Boxes.profile).get(_kRemember, defaultValue: false) as bool;

  // ---- Email + password ----

  /// Creates the account. Returns `(error, needsVerification)`:
  /// - `error != null` → failed.
  /// - `needsVerification == true` → a 6-digit code was emailed; call
  ///   [verifyEmailCode] next.
  /// - `needsVerification == false` and no error → confirmation is disabled and
  ///   the user is already signed in.
  Future<({String? error, bool needsVerification})> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_auth == null) return (error: _noCloud, needsVerification: false);
    try {
      final res = await _auth!.signUpWithEmail(email: email, password: password, fullName: name);
      if (res.session != null && res.user != null) {
        _persist(_profileFromSupabase(res.user!), remember: true);
        return (error: null, needsVerification: false);
      }
      return (error: null, needsVerification: true);
    } on AuthException catch (e) {
      return (error: e.message, needsVerification: false);
    } catch (_) {
      return (error: 'Could not create your account. Please try again.', needsVerification: false);
    }
  }

  Future<String?> verifyEmailCode({required String email, required String code}) async {
    if (_auth == null) return _noCloud;
    try {
      final res = await _auth!.verifyEmailOtp(email: email, token: code.trim());
      final user = res.user;
      if (user == null) return 'Verification failed. Please try again.';
      _persist(_profileFromSupabase(user), remember: true);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Invalid or expired code. Please try again.';
    }
  }

  Future<String?> resendCode(String email) async {
    if (_auth == null) return _noCloud;
    try {
      await _auth!.resendSignupCode(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not resend the code.';
    }
  }

  Future<String?> signInWithEmail({required String email, required String password}) async {
    if (_auth == null) return _noCloud;
    try {
      final res = await _auth!.signInWithEmail(email: email, password: password);
      final user = res.user;
      if (user == null) return 'Sign-in failed. Please try again.';
      _persist(_profileFromSupabase(user), remember: true);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not sign in. Please check your email and password.';
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    if (_auth == null) return _noCloud;
    try {
      await _auth!.sendPasswordReset(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not send the reset email.';
    }
  }

  // ---- Google (loopback id_token -> Supabase) ----

  Future<String?> signInWithGoogle() async {
    if (_auth == null) return _noCloud;
    if (!GoogleAuthConfig.isConfigured) {
      return 'Google sign-in isn\'t configured yet. Please use email for now.';
    }
    try {
      final g = await GoogleAuthService.signIn();
      if (g.idToken.isEmpty) {
        return 'Google did not return an identity token. Please try again.';
      }
      final res = await _auth!.signInWithGoogleIdToken(
        idToken: g.idToken,
        accessToken: g.accessToken.isEmpty ? null : g.accessToken,
      );
      final user = res.user;
      if (user == null) return 'Google sign-in failed. Please try again.';
      _persist(_profileFromSupabase(user), remember: true);
      return null;
    } on GoogleAuthException catch (e) {
      return e.message;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Google sign-in was cancelled or failed. Please try again.';
    }
  }

  // ---- Guest / profile / premium / sign out ----

  void continueAsGuest() {
    _persist(const UserProfile(name: 'Guest', isGuest: true), remember: false);
  }

  void updateProfile({String? name, String? email}) {
    final current = state;
    if (current == null) return;
    _persist(current.copyWith(name: name, email: email), remember: _rememberFlag);
  }

  void setPremium(bool value) {
    HiveService.dynBox(Boxes.profile).put(_kPremium, value);
    final current = state;
    if (current != null) {
      _persist(current.copyWith(isPremium: value), remember: _rememberFlag);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (_) {
      // Ignore network errors on sign-out; clear locally regardless.
    }
    HiveService.dynBox(Boxes.profile).put(_kRemember, false);
    state = null;
  }
}

final authProvider = NotifierProvider<AuthController, UserProfile?>(AuthController.new);
