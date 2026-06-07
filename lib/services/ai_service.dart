import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secrets.dart';

class AiService {
  static const _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _apiKey = Secrets.groqApiKey;

  static const _validIds = [
    'choking',
    'choking_infant',
    'cpr',
    'cpr_infant',
    'burns',
    'bleeding',
    'fractures',
    'seizures',
  ];

  static Future<String?> detectEmergency(String userInput) async {
    if (userInput.trim().isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'max_tokens': 20,
          'temperature': 0.0,
          'messages': [
            {
              'role': 'system',
              'content': '''You are an emergency triage assistant.
Given user input, respond with ONLY one of these exact IDs if it matches a medical emergency, or respond with ONLY the word "none" if it does not:
choking, choking_infant, cpr, cpr_infant, burns, bleeding, fractures, seizures

Rules:
- "infant" or "baby" or "newborn" → use the infant variant
- Respond with ONLY the ID or "none", nothing else
- If unsure, respond with "none"''',
            },
            {
              'role': 'user',
              'content': userInput,
            }
          ],
        }),
      ).timeout(const Duration(seconds: 8));

      
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final text = data['choices']?[0]?['message']?['content']
          ?.toString()
          .trim()
          .toLowerCase();

      if (text == null) return null;
      return _validIds.contains(text) ? text : null;
    } catch (e, stack) {
      print('AI error: $e');
      print('AI stack: $stack');
      return null;
    }
  }
}