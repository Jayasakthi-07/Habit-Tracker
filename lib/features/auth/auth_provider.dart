import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/hive_service.dart';
import 'google_auth_service.dart';

/// The authenticated (or guest) user profile, persisted locally.
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

/// Manages the current session: local register/login, guest mode, remember-me.
///
/// Credentials are stored locally only (this is an offline-first app); the
/// password is salted+hashed so it is never persisted in plaintext. The design
/// leaves room for a future online auth backend behind the same interface.
class AuthController extends Notifier<UserProfile?> {
  static const _kProfile = 'current_profile';
  static const _kPwHash = 'pw_hash';
  static const _kRemember = 'remember_me';

  @override
  UserProfile? build() {
    final box = HiveService.dynBox(Boxes.profile);
    final remember = box.get(_kRemember, defaultValue: false) as bool;
    final stored = box.get(_kProfile);
    if (remember && stored != null) {
      return UserProfile.fromJson(Map.from(stored as Map));
    }
    return null;
  }

  bool get hasAccount => HiveService.dynBox(Boxes.profile).get(_kPwHash) != null;

  String _hash(String password) =>
      sha256.convert(utf8.encode('aura::$password')).toString();

  void _persist(UserProfile profile, {required bool remember}) {
    final box = HiveService.dynBox(Boxes.profile);
    box.put(_kProfile, profile.toJson());
    box.put(_kRemember, remember);
    state = profile;
  }

  Future<void> register(String name, String email, String password, {bool remember = true}) async {
    final box = HiveService.dynBox(Boxes.profile);
    await box.put(_kPwHash, _hash(password));
    _persist(UserProfile(name: name, email: email), remember: remember);
  }

  /// Returns null on success, or an error message.
  String? login(String email, String password, {bool remember = true}) {
    final box = HiveService.dynBox(Boxes.profile);
    final hash = box.get(_kPwHash);
    if (hash == null) return 'No account found. Please register first.';
    if (hash != _hash(password)) return 'Incorrect password.';
    final stored = box.get(_kProfile);
    final profile = stored != null
        ? UserProfile.fromJson(Map.from(stored as Map)).copyWith(email: email)
        : UserProfile(name: email.split('@').first, email: email);
    _persist(profile, remember: remember);
    return null;
  }

  void continueAsGuest() {
    _persist(const UserProfile(name: 'Guest', isGuest: true), remember: false);
  }

  /// Signs in with Google via the desktop OAuth loopback flow.
  /// Returns null on success, or a user-facing error message.
  Future<String?> signInWithGoogle() async {
    try {
      final user = await GoogleAuthService.signIn();
      _persist(
        UserProfile(name: user.name, email: user.email, photoUrl: user.photo),
        remember: true,
      );
      return null;
    } on GoogleAuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Google sign-in was cancelled or failed. Please try again.';
    }
  }

  void updateProfile({String? name, String? email}) {
    final current = state;
    if (current == null) return;
    _persist(current.copyWith(name: name, email: email),
        remember: HiveService.dynBox(Boxes.profile).get(_kRemember, defaultValue: false) as bool);
  }

  void setPremium(bool value) {
    final current = state;
    if (current == null) return;
    _persist(current.copyWith(isPremium: value),
        remember: HiveService.dynBox(Boxes.profile).get(_kRemember, defaultValue: false) as bool);
  }

  void signOut() {
    final box = HiveService.dynBox(Boxes.profile);
    box.put(_kRemember, false);
    state = null;
  }
}

final authProvider = NotifierProvider<AuthController, UserProfile?>(AuthController.new);
