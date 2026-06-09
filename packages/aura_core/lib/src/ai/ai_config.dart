import 'ai_coach.dart';

/// AI configuration injected at build time via `--dart-define-from-file=env.json`
/// (never committed). Both providers are optional; the coach feature gates
/// itself on whether at least one key is present.
abstract class AiConfig {
  static const String geminiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String openAiKey = String.fromEnvironment('OPENAI_API_KEY');

  /// Models are overridable but have sensible, low-cost defaults.
  static const String geminiModel =
      String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-2.0-flash');
  static const String openAiModel =
      String.fromEnvironment('OPENAI_MODEL', defaultValue: 'gpt-4o-mini');

  static bool get hasGemini => geminiKey.isNotEmpty;
  static bool get hasOpenAi => openAiKey.isNotEmpty;
  static bool get anyConfigured => hasGemini || hasOpenAi;

  static bool isConfigured(AiProviderKind kind) => switch (kind) {
        AiProviderKind.gemini => hasGemini,
        AiProviderKind.openai => hasOpenAi,
      };

  /// The provider to actually use: the [preferred] one if it has a key,
  /// otherwise the first configured provider, or null if none are.
  static AiProviderKind? resolve([AiProviderKind? preferred]) {
    if (preferred != null && isConfigured(preferred)) return preferred;
    if (hasGemini) return AiProviderKind.gemini;
    if (hasOpenAi) return AiProviderKind.openai;
    return null;
  }
}
