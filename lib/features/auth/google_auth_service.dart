import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/google_auth_config.dart';

/// Basic profile + tokens returned by Google sign-in.
class GoogleUser {
  const GoogleUser({
    required this.name,
    required this.email,
    this.photo = '',
    this.idToken = '',
    this.accessToken = '',
  });
  final String name;
  final String email;
  final String photo;

  /// OIDC id_token — exchanged for a Supabase session via signInWithIdToken.
  final String idToken;
  final String accessToken;
}

class GoogleAuthException implements Exception {
  GoogleAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Google Sign-In for Windows desktop via the OAuth 2.0 Authorization Code flow
/// with PKCE over a loopback redirect.
///
/// This implementation owns the loopback HTTP listener directly (rather than a
/// library), which gives us two things:
///   1. Stronger security — PKCE (S256) + a random `state` that is validated.
///   2. Full control of the browser page shown after consent, so we render a
///      premium branded "you're signed in" screen instead of plain text.
abstract class GoogleAuthService {
  static const _authEndpoint = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const _tokenEndpoint = 'https://oauth2.googleapis.com/token';

  static final _rng = Random.secure();

  static Future<GoogleUser> signIn() async {
    final verifier = _randomUrlSafe(48);
    final challenge = _s256(verifier);
    final state = _randomUrlSafe(24);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirectUri = 'http://localhost:${server.port}';

    final authUrl = Uri.parse(_authEndpoint).replace(queryParameters: {
      'client_id': GoogleAuthConfig.clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': GoogleAuthConfig.scopes.join(' '),
      'state': state,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'prompt': 'select_account',
    });

    if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
      await server.close(force: true);
      throw GoogleAuthException('Could not open your browser for Google sign-in.');
    }

    try {
      final code = await _awaitCode(server, state)
          .timeout(const Duration(minutes: 5));
      final tokens = await _exchangeCode(code, verifier, redirectUri);
      return await _fetchProfile(tokens);
    } on TimeoutException {
      throw GoogleAuthException('Sign-in timed out. Please try again.');
    } finally {
      await server.close(force: true);
    }
  }

  /// Waits for Google's redirect, validates it, serves the branded page and
  /// returns the authorization code.
  static Future<String> _awaitCode(HttpServer server, String expectedState) async {
    await for (final req in server) {
      final params = req.uri.queryParameters;

      // Ignore unrelated requests (e.g. the browser's favicon probe).
      if (!params.containsKey('code') && !params.containsKey('error')) {
        req.response.statusCode = HttpStatus.noContent;
        await req.response.close();
        continue;
      }

      void respond(String html) {
        req.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write(html);
      }

      final error = params['error'];
      final code = params['code'];
      final state = params['state'];

      if (error != null) {
        respond(_resultPage(success: false, message: 'Sign-in was cancelled.'));
        await req.response.close();
        throw GoogleAuthException('Google sign-in was cancelled.');
      }
      if (state != expectedState || code == null) {
        respond(_resultPage(success: false, message: 'The sign-in response could not be verified.'));
        await req.response.close();
        throw GoogleAuthException('Invalid sign-in response. Please try again.');
      }

      respond(_resultPage(success: true));
      await req.response.close();
      return code;
    }
    throw GoogleAuthException('No response received from Google.');
  }

  static Future<Map<String, dynamic>> _exchangeCode(
      String code, String verifier, String redirectUri) async {
    final resp = await http.post(Uri.parse(_tokenEndpoint), body: {
      'code': code,
      'client_id': GoogleAuthConfig.clientId,
      'client_secret': GoogleAuthConfig.clientSecret,
      'redirect_uri': redirectUri,
      'grant_type': 'authorization_code',
      'code_verifier': verifier,
    });
    if (resp.statusCode != 200) {
      throw GoogleAuthException('Token exchange failed (${resp.statusCode}).');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Future<GoogleUser> _fetchProfile(Map<String, dynamic> tokens) async {
    final accessToken = tokens['access_token'] as String?;
    final idToken = tokens['id_token'] as String? ?? '';
    if (accessToken == null) {
      throw GoogleAuthException('No access token returned by Google.');
    }
    final resp = await http.get(
      Uri.parse(GoogleAuthConfig.userInfoEndpoint),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw GoogleAuthException('Could not load your Google profile (${resp.statusCode}).');
    }
    final d = jsonDecode(resp.body) as Map<String, dynamic>;
    return GoogleUser(
      name: (d['name'] ?? d['given_name'] ?? d['email'] ?? 'User').toString(),
      email: (d['email'] ?? '').toString(),
      photo: (d['picture'] ?? '').toString(),
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  // ---- PKCE helpers ----

  static String _randomUrlSafe(int bytes) {
    final data = List<int>.generate(bytes, (_) => _rng.nextInt(256));
    return base64Url.encode(data).replaceAll('=', '');
  }

  static String _s256(String verifier) {
    final digest = sha256.convert(ascii.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  // ---- Branded browser page ----

  static String _resultPage({required bool success, String message = ''}) {
    final accent = success ? '#00FF88' : '#FF5A6E';
    final accent2 = success ? '#00D4FF' : '#FF8A65';
    final title = success ? "You're all set!" : 'Sign-in incomplete';
    final body = success
        ? 'You have signed in to Aura Habits. You can close this tab and head back to the app.'
        : message;
    final glyph = success
        ? '<path class="tick" d="M28 50 L44 66 L72 34" />'
        : '<path class="tick" d="M35 35 L65 65 M65 35 L35 65" />';

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Aura Habits</title>
<style>
  :root { color-scheme: dark; }
  * { margin:0; padding:0; box-sizing:border-box; }
  html,body { height:100%; }
  body {
    font-family: 'Segoe UI', -apple-system, Roboto, Helvetica, Arial, sans-serif;
    background:#0A0A0A; color:#fff; min-height:100vh; overflow:hidden;
    display:flex; align-items:center; justify-content:center;
  }
  .bg { position:fixed; inset:0; z-index:0; }
  .glow { position:absolute; border-radius:50%; filter:blur(20px); }
  .g1 { width:620px; height:620px; top:-220px; left:-160px;
        background:radial-gradient(circle, rgba(79,70,229,0.30), transparent 70%); }
  .g2 { width:620px; height:620px; bottom:-240px; right:-160px;
        background:radial-gradient(circle, rgba(124,58,237,0.26), transparent 70%); }
  .card {
    position:relative; z-index:1; text-align:center; max-width:460px;
    padding:52px 56px; border-radius:28px;
    background:rgba(28,28,28,0.55); backdrop-filter:blur(22px);
    border:1px solid rgba(255,255,255,0.08);
    box-shadow:0 40px 90px rgba(0,0,0,0.55);
    animation:rise .7s cubic-bezier(.16,1,.3,1) both;
  }
  @keyframes rise { from { opacity:0; transform:translateY(22px) scale(.96);} to { opacity:1; transform:none; } }
  .badge { width:104px; height:104px; margin:0 auto 30px; }
  svg { width:104px; height:104px; }
  .disc { fill:url(#grad); opacity:0; transform-box:fill-box; transform-origin:center;
          animation:pop .5s cubic-bezier(.16,1,.3,1) .15s forwards; }
  .tick { stroke:#06120D; stroke-width:8; fill:none; stroke-linecap:round; stroke-linejoin:round;
          stroke-dasharray:120; stroke-dashoffset:120; animation:draw .55s ease-out .55s forwards; }
  @keyframes pop { from { opacity:0; transform:scale(.3);} to { opacity:1; transform:scale(1);} }
  @keyframes draw { to { stroke-dashoffset:0; } }
  h1 { font-size:27px; font-weight:800; letter-spacing:-.3px; margin-bottom:12px;
       background:linear-gradient(90deg, $accent, $accent2);
       -webkit-background-clip:text; background-clip:text; color:transparent;
       animation:fade .6s ease .35s both; }
  p { color:#A0A0A0; font-size:15px; line-height:1.65; animation:fade .6s ease .5s both; }
  .brand { margin-top:32px; display:flex; align-items:center; justify-content:center; gap:10px;
           color:#6B6B6B; font-size:12px; letter-spacing:3px; text-transform:uppercase;
           animation:fade .6s ease .65s both; }
  .dot { width:9px; height:9px; border-radius:50%;
         background:linear-gradient(135deg,#00FF88,#00D4FF); box-shadow:0 0 14px rgba(0,255,136,.6); }
  .hint { margin-top:20px; font-size:12px; color:#555; animation:fade .6s ease .8s both; }
  @keyframes fade { from { opacity:0; transform:translateY(8px);} to { opacity:1; transform:none; } }
</style>
</head>
<body>
  <div class="bg"><div class="glow g1"></div><div class="glow g2"></div></div>
  <div class="card">
    <div class="badge">
      <svg viewBox="0 0 100 100">
        <defs>
          <linearGradient id="grad" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stop-color="$accent" />
            <stop offset="1" stop-color="$accent2" />
          </linearGradient>
        </defs>
        <circle class="disc" cx="50" cy="50" r="46" />
        $glyph
      </svg>
    </div>
    <h1>$title</h1>
    <p>$body</p>
    <div class="hint">This tab will try to close itself automatically…</div>
    <div class="brand"><span class="dot"></span> Aura Habits</div>
  </div>
  <script>setTimeout(function(){ try { window.close(); } catch (e) {} }, 2600);</script>
</body>
</html>
''';
  }
}
