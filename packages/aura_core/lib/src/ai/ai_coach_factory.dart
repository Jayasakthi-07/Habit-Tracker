import 'ai_coach.dart';
import 'ai_config.dart';
import 'gemini_coach.dart';
import 'openai_coach.dart';
import 'openrouter_coach.dart';

/// Builds [AiCoach]es from the keys/models in [AiConfig]. Returns null when the
/// requested (or any) provider is unconfigured.
abstract class AiCoachFactory {
  static AiCoach? create(AiProviderKind kind) {
    switch (kind) {
      case AiProviderKind.openrouter:
        if (!AiConfig.hasOpenRouter) return null;
        return OpenRouterCoach(
            apiKey: AiConfig.openRouterKey, model: AiConfig.openRouterModel);
      case AiProviderKind.openai:
        if (!AiConfig.hasOpenAi) return null;
        return OpenAiCoach(
            apiKey: AiConfig.openAiKey, model: AiConfig.openAiModel);
      case AiProviderKind.gemini:
        if (!AiConfig.hasGemini) return null;
        return GeminiCoach(
            apiKey: AiConfig.geminiKey, model: AiConfig.geminiModel);
    }
  }

  /// The coach for [preferred] if configured, else the first available one.
  static AiCoach? resolve([AiProviderKind? preferred]) {
    final kind = AiConfig.resolve(preferred);
    return kind == null ? null : create(kind);
  }

  /// Ordered list of configured coaches to try in turn: [preferred] first (if
  /// set + configured), then the remaining providers by [AiConfig.priority]
  /// (OpenRouter → OpenAI → Gemini). Used to fall back automatically when the
  /// first provider errors out.
  static List<AiCoach> fallbackChain([AiProviderKind? preferred]) {
    final order = <AiProviderKind>[];
    if (preferred != null) order.add(preferred);
    for (final k in AiConfig.priority) {
      if (!order.contains(k)) order.add(k);
    }
    return order
        .map(create)
        .whereType<AiCoach>()
        .toList(growable: false);
  }
}
