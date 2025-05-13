import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/util/api_keys.dart';
import '../models/voice_command_model.dart';

abstract class AIDataSource {
  Future<VoiceCommandModel> processTextToCommand(String text);
}

class GeminiAIDataSource implements AIDataSource {
  final GenerativeModel _model;

  GeminiAIDataSource() : _model = GenerativeModel(
    model: 'gemini-pro',
    apiKey: ApiKeys.geminiApiKey,
  );

  @override
  Future<VoiceCommandModel> processTextToCommand(String text) async {
    try {
      final prompt = '''
You are a voice assistant for a service booking app. Convert this voice input into JSON that the backend can understand.
Voice Input: "$text"
Respond only with a valid JSON format like:
{
  "action": "[appropriate action like book_appointment, check_status, cancel_booking, etc]",
  "location": "[location mentioned or null if not specified]",
  "date": "[date in YYYY-MM-DD format or null if not specified]"
}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text ?? '';

      // Extract JSON from the response
      final jsonData = _extractJsonFromResponse(responseText);

      return VoiceCommandModel.fromJson(jsonData);
    } catch (e) {
      return VoiceCommandModel(
        action: 'error',
        location: null,
        date: null,
      );
    }
  }

  Map<String, dynamic> _extractJsonFromResponse(String response) {
    try {
      // Find JSON content in the response (handling cases where there might be text before/after the JSON)
      final jsonPattern = RegExp(r'{[\s\S]*?}');
      final match = jsonPattern.firstMatch(response);

      if (match != null) {
        final jsonString = match.group(0);
        if (jsonString != null) {
          return json.decode(jsonString);
        }
      }
      return {'action': 'unknown', 'location': null, 'date': null};
    } catch (e) {
      return {'action': 'error', 'location': null, 'date': null};
    }
  }
}