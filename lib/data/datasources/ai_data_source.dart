import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    if (text.isEmpty) {
      return VoiceCommandModel(action: 'error', location: null, date: null);
    }

    try {
      debugPrint('Processing text with AI: $text');

      final prompt = '''
You are an AI assistant for a service booking app. Convert this voice input into structured JSON format.
Voice Input: "$text"

Analyze the input and extract the following information:
1. What action is the user trying to perform? Choose one of:
   - book_appointment (for scheduling or booking services)
   - cancel_booking (for canceling existing appointments)
   - reschedule (for changing appointment time)
   - check_status (for checking status of bookings)
   - get_info (for requesting information about services)
   - purchase (for buying items or services)

2. Any location mentioned
3. Any date/time mentioned (format as YYYY-MM-DD)

Respond ONLY with a valid JSON object in this exact format, nothing else:
{
  "action": "one_of_the_actions_above",
  "location": "location_mentioned_or_null",
  "date": "date_in_YYYY-MM-DD_format_or_null"
}

If you can't determine one of the fields, use null for that field. Be accurate and precise.
''';

      final content = [Content.text(prompt)];

      // Set safety settings to be more permissive for simple command extraction
      final generationConfig = GenerationConfig(
        temperature: 0.2, // Low temperature for more deterministic answers
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 100, // Short response for just the JSON
      );

      final response = await _model.generateContent(
        content,
        generationConfig: generationConfig,
      );

      final responseText = response.text ?? '';

      debugPrint('AI Response: $responseText');

      // Extract JSON from the response
      final jsonData = _extractJsonFromResponse(responseText);

      debugPrint('Extracted JSON: $jsonData');

      return VoiceCommandModel.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error processing with AI: $e');
      return VoiceCommandModel(
        action: 'error',
        location: null,
        date: null,
      );
    }
  }

  Map<String, dynamic> _extractJsonFromResponse(String response) {
    try {
      // Clean up the response to handle potential markdown formatting
      String cleanResponse = response.replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Find JSON content in the response (handling cases where there might be text before/after the JSON)
      final jsonPattern = RegExp(r'{[\s\S]*?}');
      final match = jsonPattern.firstMatch(cleanResponse);

      if (match != null) {
        final jsonString = match.group(0);
        if (jsonString != null) {
          try {
            return json.decode(jsonString);
          } catch (e) {
            debugPrint('Failed to parse extracted JSON pattern: $e');
          }
        }
      }

      // If no JSON pattern found, try to parse the entire response
      try {
        return json.decode(cleanResponse);
      } catch (e) {
        debugPrint('Failed to parse entire response as JSON: $e');

        // As a fallback, try to construct a reasonable JSON from the text
        if (response.toLowerCase().contains('book') ||
            response.toLowerCase().contains('appointment')) {
          return {'action': 'book_appointment', 'location': null, 'date': null};
        } else if (response.toLowerCase().contains('cancel')) {
          return {'action': 'cancel_booking', 'location': null, 'date': null};
        } else if (response.toLowerCase().contains('purchase')) {
          return {'action': 'purchase', 'location': null, 'date': null};
        } else {
          return {'action': 'unknown', 'location': null, 'date': null};
        }
      }
    } catch (e) {
      debugPrint('Error extracting JSON: $e');
      return {'action': 'error', 'location': null, 'date': null};
    }
  }
}