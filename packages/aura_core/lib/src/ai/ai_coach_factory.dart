import 'ai_coach.dart';
import 'ai_config.dart';
import 'gemini_coach.dart';
import 'openai_coach.dart';

/// Builds the right [AiCoach] for a provider using the keys/models in
/// [AiConfig]. Returns null when the requested (or any) provider is unconfigured.
abstract class AiCoachFactory {
  static AiCoach? create(AiProviderKind kind) {
    switch (kind) {
      case AiProviderKind.gemini:
        if (!AiConfig.hasGemini) return null;
        return GeminiCoach(
            apiKey: AiConfig.geminiKey, model: AiConfig.geminiModel);
      case AiProviderKind.openai:
        if (!AiConfig.hasOpenAi) return null;
        return OpenAiCoach(
            apiKey: AiConfig.openAiKey, model: AiConfig.openAiModel);
    }
  }

  /// The coach for [preferred] if configured, else the first available one.
  static AiCoach? resolve([AiProviderKind? preferred]) {
    final kind = AiConfig.resolve(preferred);
    return kind == null ? null : create(kind);
  }
}
