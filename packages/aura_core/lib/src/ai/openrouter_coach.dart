import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_coach.dart';

/// OpenRouter implementation. OpenRouter exposes an **OpenAI-compatible** Chat
/// Completions endpoint, so the request/response shape matches OpenAI; only the
/// base URL, the model id namespace (e.g. `openai/gpt-4o-mini`), and the
/// recommended attribution headers differ.
class OpenRouterCoach implements AiCoach {
  OpenRouterCoach({required this.apiKey, this.model = 'openai/gpt-4o-mini'});

  final String apiKey;
  final String model;

  @override
  AiProviderKind get kind => AiProviderKind.openrouter;

  @override
  Future<String> chat({required String system, required String user}) async {
    final uri = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

    http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
              // OpenRouter attribution (optional but recommended).
              'HTTP-Referer': 'https://aurahabits.app',
              'X-Title': 'Aura Habits',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'system', 'content': system},
                {'role': 'user', 'content': user},
              ],
              'temperature': 0.7,
              'max_tokens': 800,
            }),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw AiException('Could not reach OpenRouter. Check your connection.');
    }

    if (res.statusCode != 200) {
      throw AiException(_friendlyError(res.statusCode));
    }

    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final choices = json['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw AiException('OpenRouter returned no answer. Try rephrasing.');
      }
      final text =
          (choices.first['message']?['content'] ?? '').toString().trim();
      if (text.isEmpty) throw AiException('OpenRouter returned an empty answer.');
      return text;
    } on AiException {
      rethrow;
    } catch (_) {
      throw AiException('Unexpected response from OpenRouter.');
    }
  }

  String _friendlyError(int code) {
    if (code == 401) {
      return 'OpenRouter rejected the request — check your API key.';
    }
    if (code == 402) return 'OpenRouter credits exhausted.';
    if (code == 429) return 'OpenRouter rate limit reached. Try again shortly.';
    return 'OpenRouter error ($code).';
  }
}
