import 'ai_coach.dart';

/// AI configuration injected at build time via `--dart-define-from-file=env.json`
/// (never committed). All providers are optional; the coach feature gates
/// itself on whether at least one key is present.
///
/// Priority order is **OpenRouter → OpenAI → Gemini**: OpenRouter is preferred
/// (it can route to many models behind one key) and OpenAI is the fallback.
abstract class AiConfig {
  static const String _envOpenRouterKey =
      String.fromEnvironment('OPENROUTER_API_KEY');
  static const String _envOpenAiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String _envGeminiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Runtime keys, supplied by the user through the app's settings UI and
  /// persisted locally. They take precedence over build-time keys so public
  /// release builds — which deliberately ship with NO embedded keys — can
  /// still unlock AI coaching once the user pastes their own key.
  static String runtimeOpenRouterKey = '';
  static String runtimeOpenAiKey = '';
  static String runtimeGeminiKey = '';

  static String get openRouterKey =>
      runtimeOpenRouterKey.isNotEmpty ? runtimeOpenRouterKey : _envOpenRouterKey;
  static String get openAiKey =>
      runtimeOpenAiKey.isNotEmpty ? runtimeOpenAiKey : _envOpenAiKey;
  static String get geminiKey =>
      runtimeGeminiKey.isNotEmpty ? runtimeGeminiKey : _envGeminiKey;

  /// Models are overridable but have sensible, low-cost defaults.
  static const String openRouterModel = String.fromEnvironment(
      'OPENROUTER_MODEL',
      defaultValue: 'openai/gpt-4o-mini');
  static const String openAiModel =
      String.fromEnvironment('OPENAI_MODEL', defaultValue: 'gpt-4o-mini');
  static const String geminiModel =
      String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-2.0-flash');

  static bool get hasOpenRouter => openRouterKey.isNotEmpty;
  static bool get hasOpenAi => openAiKey.isNotEmpty;
  static bool get hasGemini => geminiKey.isNotEmpty;
  static bool get anyConfigured => hasOpenRouter || hasOpenAi || hasGemini;

  /// Global priority order — used for default selection and fallback chains.
  static const List<AiProviderKind> priority = [
    AiProviderKind.openrouter,
    AiProviderKind.openai,
    AiProviderKind.gemini,
  ];

  static bool isConfigured(AiProviderKind kind) => switch (kind) {
        AiProviderKind.openrouter => hasOpenRouter,
        AiProviderKind.openai => hasOpenAi,
        AiProviderKind.gemini => hasGemini,
      };

  /// The provider to use: the [preferred] one if it has a key, otherwise the
  /// first configured provider by [priority], or null if none are configured.
  static AiProviderKind? resolve([AiProviderKind? preferred]) {
    if (preferred != null && isConfigured(preferred)) return preferred;
    for (final k in priority) {
      if (isConfigured(k)) return k;
    }
    return null;
  }
}
