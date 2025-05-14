import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/util/api_keys.dart';
import '../models/voice_command_model.dart';

abstract class AIDataSource {
  Future<VoiceCommandModel> processTextToCommand(String text,
      {String? commandMode});

  Future<String> detectLanguage(String text);

  Future<String> translateToEnglish(String text, String sourceLanguage);

  Future<String> translateFromEnglish(String text, String targetLanguage);

  Future<List<String>> generateItemList(String text);

  Future<String> improveTranscriptionAccuracy(String text);

  Future<Map<String, dynamic>> generateBillFromText(String text);
}

class GeminiAIDataSource implements AIDataSource {
  final GenerativeModel _model;

  GeminiAIDataSource() : _model = GenerativeModel(
    model: 'gemini-pro',
    apiKey: ApiKeys.geminiApiKey,
  );

  @override
  Future<VoiceCommandModel> processTextToCommand(String text,
      {String? commandMode}) async {
    if (text.isEmpty) {
      return VoiceCommandModel(action: 'error', location: null, date: null);
    }

    try {
      debugPrint('Processing text with AI: $text');
      debugPrint('Command mode: ${commandMode ?? "default"}');

      // Detect language first
      final detectedLanguage = await detectLanguage(text);

      // Translate to English if not already in English
      String processedText = text;
      if (detectedLanguage != 'en') {
        processedText = await translateToEnglish(text, detectedLanguage);
        debugPrint('Translated text: $processedText');
      }

      // Improve transcription accuracy
      processedText = await improveTranscriptionAccuracy(processedText);
      debugPrint('Improved transcription: $processedText');

      final prompt = _buildServerJsonPrompt(processedText, commandMode);

      final content = [Content.text(prompt)];

      final generationConfig = GenerationConfig(
        temperature: 0.1,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 200,
      );

      final response = await _model.generateContent(
        content,
        generationConfig: generationConfig,
      );

      final responseText = response.text ?? '';

      debugPrint('AI Response: $responseText');

      // Extract JSON from the response
      final jsonData = _extractJsonFromResponse(responseText);

      // Add the detected language to the command model
      if (!jsonData.containsKey('language') || jsonData['language'] == null) {
        jsonData['language'] = detectedLanguage;
      }

      // Add the original text for reference
      if (!jsonData.containsKey('original_text') ||
          jsonData['original_text'] == null) {
        jsonData['original_text'] = text;
      }

      // Add processed text if translation or improvement happened
      if (text != processedText &&
          (!jsonData.containsKey('processed_text') ||
              jsonData['processed_text'] == null)) {
        jsonData['processed_text'] = processedText;
      }

      // Add timestamp
      if (!jsonData.containsKey('timestamp') || jsonData['timestamp'] == null) {
        jsonData['timestamp'] = DateTime.now().toIso8601String();
      }

      debugPrint('Final JSON: $jsonData');
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

  @override
  Future<String> detectLanguage(String text) async {
    if (text.isEmpty) return 'en';

    try {
      final prompt = '''
You are an expert in language detection. Analyze the following text and detect what language it is written in. 
Pay special attention to South Indian languages (Tamil, Telugu, Malayalam, Kannada).
Tamil text often includes words like "na", "enna", "panni", "pannitu", "pesuratha", "varanum" etc.

IMPORTANT NOTES FOR TAMIL DETECTION:
1. Words like "na", "naa", "nan", "naan" (meaning "I" or "me")
2. Phrases like "pesura" or "pesurathu" (meaning "speaking")
3. Words ending with "anum" like "varanum", "tharanum" (meaning "should come", "should give")
4. Words containing "kettu" (meaning "hearing" or "listening")
5. Words with "accurate", "accuracy" or "result" may be English words used in Tamil sentences

Even with just a few Tamil words mixed with English, classify it as Tamil (ta) if the sentence structure follows Tamil patterns.

Respond with ONLY the two-letter ISO language code (e.g., 'en' for English, 'ta' for Tamil, 'te' for Telugu, 'ml' for Malayalam, 'hi' for Hindi, etc.).
If you're not sure, respond with 'en'.

Even if you don't recognize the language exactly, try to provide the closest matching language code.

Text: "$text"
''';

      final content = [Content.text(prompt)];

      final generationConfig = GenerationConfig(
        temperature: 0.1,
        topP: 0.95,
        maxOutputTokens: 50,
      );

      final response = await _model.generateContent(
        content,
        generationConfig: generationConfig,
      );

      final detectedLanguage = response.text?.trim().toLowerCase() ?? 'en';
      final cleanLanguage = detectedLanguage.replaceAll(
          RegExp(r'[^a-z\-]'), '');

      final languageMap = {
        'english': 'en',
        'tamil': 'ta',
        'telugu': 'te',
        'malayalam': 'ml',
        'hindi': 'hi',
        'bengali': 'bn',
        'kannada': 'kn',
      };

      final result = languageMap[cleanLanguage] ??
          (cleanLanguage.length <= 5 ? cleanLanguage : 'en');

      debugPrint('Detected language: $result');
      return result;
    } catch (e) {
      debugPrint('Error detecting language: $e');
      return 'en';
    }
  }

  // Helper method to detect Tamil language patterns
  bool containsTamilPatterns(String text) {
    final lowerText = text.toLowerCase();
    final tamilPatterns = [
      'na pesur', 'naa pesur', 'nan pesur', 'naan pesur',
      'pesura', 'pesurathu', 'pesuradhu',
      'tharanum', 'varanum', 'ketku', 'kettu',
      'athu kettu', 'adhu kettu',
      'result thar', 'accurate aa'
    ];

    for (final pattern in tamilPatterns) {
      if (lowerText.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  @override
  Future<String> translateToEnglish(String text, String sourceLanguage) async {
    if (text.isEmpty) return '';
    if (sourceLanguage == 'en') return text;

    try {
      final prompt = '''
Translate this text to English:
"$text"
''';

      final content = [Content.text(prompt)];
      final generationConfig = GenerationConfig(
        temperature: 0.1,
        maxOutputTokens: 1000,
      );

      final response = await _model.generateContent(
        content,
        generationConfig: generationConfig,
      );

      final translatedText = response.text?.trim() ?? text;
      debugPrint('Translated from $sourceLanguage to English: $translatedText');
      return translatedText;
    } catch (e) {
      debugPrint('Error translating text: $e');
      return text;
    }
  }

  @override
  Future<String> translateFromEnglish(String text,
      String targetLanguage) async {
    if (text.isEmpty) return '';
    if (targetLanguage == 'en') return text;

    try {
      final prompt = '''
Translate this English text to ${_getLanguageName(targetLanguage)}:
"$text"
''';

      final content = [Content.text(prompt)];
      final generationConfig = GenerationConfig(
        temperature: 0.1,
        maxOutputTokens: 1000,
      );

      final response = await _model.generateContent(
        content,
        generationConfig: generationConfig,
      );

      final translatedText = response.text?.trim() ?? text;
      debugPrint('Translated from English to $targetLanguage: $translatedText');
      return translatedText;
    } catch (e) {
      debugPrint('Error translating text: $e');
      return text;
    }
  }

  @override
  Future<List<String>> generateItemList(String text) async {
    if (text.isEmpty) return [];

    try {
      final prompt = '''
Based on this text, generate a list of items as a JSON array:
"$text"

Example response format: ["item1", "item2", "item3"]
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text?.trim() ?? '[]';

      final pattern = RegExp(r'\[.*\]');
      final match = pattern.firstMatch(responseText);

      if (match != null) {
        final jsonString = match.group(0);
        if (jsonString != null) {
          try {
            final List<dynamic> items = json.decode(jsonString);
            return items.map((item) => item.toString()).toList();
          } catch (e) {
            debugPrint('Error parsing JSON array: $e');
          }
        }
      }

      final items = responseText
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      return items;
    } catch (e) {
      debugPrint('Error generating item list: $e');
      return [];
    }
  }

  @override
  Future<String> improveTranscriptionAccuracy(String text) async {
    if (text.isEmpty) return '';

    try {
      final prompt = '''
Improve the accuracy of this voice transcription by fixing any errors:
"$text"
''';

      final content = [Content.text(prompt)];
      final generationConfig = GenerationConfig(
        temperature: 0.2,
        maxOutputTokens: 1000,
      );

      final response = await _model.generateContent(
        content,
        generationConfig: generationConfig,
      );

      final improvedText = response.text?.trim() ?? text;
      debugPrint('Improved transcription: $improvedText');
      return improvedText;
    } catch (e) {
      debugPrint('Error improving transcription: $e');
      return text;
    }
  }

  @override
  Future<Map<String, dynamic>> generateBillFromText(String text) async {
    if (text.isEmpty) return {'error': 'No text provided'};

    try {
      final prompt = '''
Generate a bill/receipt from this purchase description as JSON:
"$text"

Include: items, quantities, prices, total, date, and store name.
''';

      final content = [Content.text(prompt)];
      final generationConfig = GenerationConfig(
        temperature: 0.1,
        maxOutputTokens: 2000,
      );

      final response = await _model.generateContent(
        content,
        generationConfig: generationConfig,
      );

      final responseText = response.text?.trim() ?? '{}';

      try {
        String cleanResponse = responseText.replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final jsonPattern = RegExp(r'{[\s\S]*?}');
        final match = jsonPattern.firstMatch(cleanResponse);

        if (match != null) {
          final jsonString = match.group(0);
          if (jsonString != null) {
            return json.decode(jsonString);
          } else {
            return json.decode(cleanResponse);
          }
        } else {
          return json.decode(cleanResponse);
        }
      } catch (e) {
        debugPrint('Error parsing bill JSON: $e');
        return {
          'error': 'Failed to parse bill data',
          'rawText': responseText
        };
      }
    } catch (e) {
      debugPrint('Error generating bill: $e');
      return {'error': 'Error generating bill: $e'};
    }
  }

  String _getLanguageName(String languageCode) {
    final languageNames = {
      'en': 'English',
      'ta': 'Tamil',
      'te': 'Telugu',
      'ml': 'Malayalam',
      'hi': 'Hindi',
      'bn': 'Bengali',
      'kn': 'Kannada',
      'mr': 'Marathi',
      'pa': 'Punjabi',
      'gu': 'Gujarati',
      'or': 'Odia',
      'ur': 'Urdu',
      'fr': 'French',
      'es': 'Spanish',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
      'ar': 'Arabic',
    };

    return languageNames[languageCode] ?? languageCode.toUpperCase();
  }

  String _buildServerJsonPrompt(String text, String? commandMode) {
    if (commandMode == 'transaction') {
      final today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD

      // Detect language from text for better prompting
      String language = 'english';
      if (_containsIndianLanguage(text)) {
        if (_containsTamilWords(text)) {
          language = 'tamil';
        } else if (_containsHindiWords(text)) {
          language = 'hindi';
        }
      } else if (_containsSpanishWords(text)) {
        language = 'spanish';
      }

      // Base English prompt
      String basePrompt = '''Extract the following transaction details from this sentence:
"$text"

Return in JSON format:
{
  "type": "expense", // or "income"
  "amount": <amount>,
  "category": "<category>",
  "date": "<yyyy-mm-dd>"
}

Today's date is $today.''';

      // For languages other than English
      switch (language.toLowerCase()) {
        case 'tamil':
          return '''இந்த வாக்கியத்திலிருந்து பின்வரும் பரிவர்த்தனை விவரங்களை பிரித்தெடுக்கவும்:
"$text"

JSON வடிவத்தில் திரும்பி:
{
  "type": "expense", // அல்லது "income"
  "amount": <amount>,
  "category": "<category>",
  "date": "<yyyy-mm-dd>"
}

இன்றைய தேதி $today.''';
        case 'hindi':
          return '''इस वाक्य से निम्नलिखित लेनदेन विवरण निकालें:
"$text"

JSON प्रारूप में वापस करें:
{
  "type": "expense", // या "income"
  "amount": <amount>,
  "category": "<category>",
  "date": "<yyyy-mm-dd>"
}

आज की तारीख है $today.''';
        case 'spanish':
          return '''Extraiga los siguientes detalles de la transacción de esta frase:
"$text"

Devuelva en formato JSON:
{
  "type": "expense", // o "income"
  "amount": <amount>,
  "category": "<category>",
  "date": "<yyyy-mm-dd>"
}

La fecha de hoy es $today.''';
        default:
          return basePrompt;
      }
    } else if (commandMode == 'app_query') {
      return '''
Convert this app query to JSON format with action="app_query" and query field:
"$text"
''';
    } else {
      return '''
Convert this voice input to JSON with appropriate action (add_transaction, app_query, generate_list, etc.) and relevant fields:
"$text"
''';
    }
  }

  bool _containsIndianLanguage(String text) {
    // Check for common patterns in Indian languages
    final indianPatterns = [
      'रुपये', 'रु', '₹', 'के लिए', 'खर्च',
      'ரூபாய்', 'செலவு', 'வரவு', 'காசு',
      'రూపాయలు', 'ఖర్చు', 'రూ'
    ];
    return indianPatterns.any((pattern) =>
        text.toLowerCase().contains(pattern.toLowerCase()));
  }

  bool _containsTamilWords(String text) {
    // Check for common Tamil words related to transactions
    final tamilPatterns = [
      'ரூபாய்', 'செலவு', 'வரவு', 'காசு',
      'வாங்கினேன்', 'செலுத்தினேன்', 'பணம்'
    ];
    return tamilPatterns.any((pattern) =>
        text.toLowerCase().contains(pattern.toLowerCase()));
  }

  bool _containsHindiWords(String text) {
    // Check for common Hindi words related to transactions
    final hindiPatterns = [
      'रुपये', 'खर्च', 'आय', 'पैसा',
      'खरीदा', 'भुगतान', 'बिल'
    ];
    return hindiPatterns.any((pattern) =>
        text.toLowerCase().contains(pattern.toLowerCase()));
  }

  bool _containsSpanishWords(String text) {
    // Check for common Spanish words related to transactions
    final spanishPatterns = [
      'euro', 'euros', 'gasto', 'ingreso', 'dinero',
      'compré', 'pagué', 'factura'
    ];
    return spanishPatterns.any((pattern) =>
        text.toLowerCase().contains(pattern.toLowerCase()));
  }

  Map<String, dynamic> _extractJsonFromResponse(String response) {
    try {
      String cleanResponse = response.replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

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

      try {
        return json.decode(cleanResponse);
      } catch (e) {
        debugPrint('Failed to parse entire response as JSON: $e');

        // More aggressive transaction detection
        if (response.toLowerCase().contains('transaction') ||
            response.toLowerCase().contains('amount') ||
            response.toLowerCase().contains('spent') ||
            response.toLowerCase().contains('expense') ||
            response.toLowerCase().contains('cost') ||
            response.toLowerCase().contains('₹') ||
            response.toLowerCase().contains('rs.') ||
            response.toLowerCase().contains('rs ') ||
            response.toLowerCase().contains('rupees') ||
            response.toLowerCase().contains('rupee') ||
            RegExp(r'\b\d+\s*(rs|₹|rupees?)\b', caseSensitive: false).hasMatch(
                response) ||
            RegExp(r'(rs|₹|rupees?)\s*\d+', caseSensitive: false).hasMatch(
                response) ||
            response.toLowerCase().contains('rs') ||
            response.toLowerCase().contains('ரூபாய்') ||
            response.toLowerCase().contains('செலவு') ||
            response.toLowerCase().contains('பணம்') ||
            RegExp(r'\b\d+\s*(ரூபாய்|ரூ)\b', caseSensitive: false).hasMatch(
                response) ||
            RegExp(r'(ரூபாய்|ரூ)\s*\d+', caseSensitive: false).hasMatch(
                response)) {
          // Log what was detected to help debug
          debugPrint('Transaction detected in text: $response');
          return {
            'action': 'add_transaction',
            'amount': _extractAmountFromText(response),
            'category': _extractCategoryFromText(response),
            'date': null,
            'language': 'en'
          };
        } else if (response.toLowerCase().contains('income') ||
            response.toLowerCase().contains('salary') ||
            response.toLowerCase().contains('received')) {
          return {
            'action': 'add_income',
            'amount': null,
            'category': null,
            'date': null,
            'language': 'en'
          };
        } else if (response.toLowerCase().contains('list') ||
            response.toLowerCase().contains('items') ||
            response.toLowerCase().contains('groceries')) {
          return {
            'action': 'generate_list',
            'list_description': 'shopping list',
            'language': 'en'
          };
        } else if (response.toLowerCase().contains('how') ||
            response.toLowerCase().contains('what') ||
            response.toLowerCase().contains('why') ||
            response.toLowerCase().contains('?')) {
          return {'action': 'app_query', 'query': response, 'language': 'en'};
        } else {
          return {'action': 'unknown', 'language': 'en'};
        }
      }
    } catch (e) {
      debugPrint('Error extracting JSON: $e');
      return {'action': 'error', 'language': 'en'};
    }
  }

  // Helper method to extract amount from text
  double? _extractAmountFromText(String text) {
    // Try to find numbers preceded or followed by currency symbols
    final amountRegex1 = RegExp(
        r'(\d+(?:\.\d+)?)\s*(rs|₹|rupees?)', caseSensitive: false);
    final amountRegex2 = RegExp(
        r'(rs|₹|rupees?)\s*(\d+(?:\.\d+)?)', caseSensitive: false);

    Match? match = amountRegex1.firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '0');
    }

    match = amountRegex2.firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(2) ?? '0');
    }

    // Try to find standalone numbers
    final numberRegex = RegExp(r'\b(\d+(?:\.\d+)?)\b');
    match = numberRegex.firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '0');
    }

    return null;
  }

  // Helper method to extract category from text
  String? _extractCategoryFromText(String text) {
    // Common expense categories
    final categories = [
      'grocery', 'food', 'restaurant', 'transport', 'travel',
      'fuel', 'petrol', 'shopping', 'clothes', 'bills', 'rent',
      'utilities', 'medical', 'health', 'entertainment', 'education',
      'salary', 'investment', 'gift', 'other'
    ];

    // Tamil categories with English equivalents
    final tamilCategories = {
      'உணவு': 'food',
      'சாப்பாடு': 'food',
      'மளிகை': 'grocery',
      'போக்குவரத்து': 'transport',
      'பயணம்': 'travel',
      'எரிபொருள்': 'fuel',
      'ஷாப்பிங்': 'shopping',
      'ஆடைகள்': 'clothes',
      'மருத்துவம்': 'medical',
      'கல்வி': 'education',
      'சம்பளம்': 'salary',
      'வாடகை': 'rent',
    };

    // First try exact matches
    for (final category in categories) {
      if (text.toLowerCase().contains(category)) {
        return category;
      }
    }

    // Try Tamil category matches
    for (final entry in tamilCategories.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }

    // Check for "for" pattern (e.g. "spent 500 for groceries")
    final forRegex = RegExp(r'for\s+([a-zA-Z]+)', caseSensitive: false);
    final match = forRegex.firstMatch(text);
    if (match != null) {
      return match.group(1);
    }

    // Check for Tamil "for" pattern (e.g. "500 ரூபாய் மளிகைக்காக")
    final tamilForRegex = RegExp(
        r'(க்காக|க்கு)\s+([^\s]+)', caseSensitive: false);
    final tamilMatch = tamilForRegex.firstMatch(text);
    if (tamilMatch != null) {
      return tamilMatch.group(2) ?? 'Misc';
    }

    return 'Misc'; // Default category
  }
}