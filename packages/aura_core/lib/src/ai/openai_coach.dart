import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_coach.dart';

/// OpenAI implementation via the Chat Completions REST API. The API key is sent
/// as a Bearer token.
class OpenAiCoach implements AiCoach {
  OpenAiCoach({required this.apiKey, this.model = 'gpt-4o-mini'});

  final String apiKey;
  final String model;

  @override
  AiProviderKind get kind => AiProviderKind.openai;

  @override
  Future<String> chat({required String system, required String user}) async {
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

    http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
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
      throw AiException('Could not reach OpenAI. Check your connection.');
    }

    if (res.statusCode != 200) {
      throw AiException(_friendlyError(res.statusCode));
    }

    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final choices = json['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw AiException('OpenAI returned no answer. Try rephrasing.');
      }
      final text =
          (choices.first['message']?['content'] ?? '').toString().trim();
      if (text.isEmpty) throw AiException('OpenAI returned an empty answer.');
      return text;
    } on AiException {
      rethrow;
    } catch (_) {
      throw AiException('Unexpected response from OpenAI.');
    }
  }

  String _friendlyError(int code) {
    if (code == 401) return 'OpenAI rejected the request — check your API key.';
    if (code == 429) {
      return 'OpenAI rate limit or quota reached. Try again later.';
    }
    return 'OpenAI error ($code).';
  }
}
