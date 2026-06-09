/// Which AI backend powers the coach. Both are supported behind this one
/// interface and are user-selectable (a locked product decision).
enum AiProviderKind {
  gemini,
  openai;

  String get label => switch (this) {
        AiProviderKind.gemini => 'Google Gemini',
        AiProviderKind.openai => 'OpenAI',
      };

  static AiProviderKind fromName(String? name, AiProviderKind fallback) {
    for (final v in AiProviderKind.values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}

/// Raised when an AI request fails (network, auth, quota, or bad response).
class AiException implements Exception {
  AiException(this.message);
  final String message;
  @override
  String toString() => 'AiException: $message';
}

/// A single AI text-completion backend. Implementations (Gemini, OpenAI) each
/// translate to/from their own REST shape so the app talks to one interface.
abstract class AiCoach {
  AiProviderKind get kind;

  /// Sends a [system] instruction + [user] message and returns the model's
  /// plain-text reply. Throws [AiException] on failure.
  Future<String> chat({required String system, required String user});
}
