import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_coach.dart';

/// Google Gemini implementation via the Generative Language REST API
/// (`generateContent`). The API key is passed as a query parameter.
class GeminiCoach implements AiCoach {
  GeminiCoach({required this.apiKey, this.model = 'gemini-2.0-flash'});

  final String apiKey;
  final String model;

  @override
  AiProviderKind get kind => AiProviderKind.gemini;

  @override
  Future<String> chat({required String system, required String user}) async {
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

    http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'system_instruction': {
                'parts': [
                  {'text': system}
                ]
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': user}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.7,
                'maxOutputTokens': 800,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw AiException('Could not reach Gemini. Check your connection.');
    }

    if (res.statusCode != 200) {
      throw AiException(_friendlyError(res.statusCode, res.body));
    }

    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        // Often a safety block — surface a gentle message.
        throw AiException('Gemini returned no answer. Try rephrasing.');
      }
      final parts = (candidates.first['content']?['parts'] as List?) ?? const [];
      final text =
          parts.map((p) => (p as Map)['text'] ?? '').join().toString().trim();
      if (text.isEmpty) throw AiException('Gemini returned an empty answer.');
      return text;
    } on AiException {
      rethrow;
    } catch (_) {
      throw AiException('Unexpected response from Gemini.');
    }
  }

  String _friendlyError(int code, String body) {
    if (code == 400 || code == 403) {
      return 'Gemini rejected the request — check your API key.';
    }
    if (code == 429) return 'Gemini rate limit reached. Try again shortly.';
    return 'Gemini error ($code).';
  }
}
