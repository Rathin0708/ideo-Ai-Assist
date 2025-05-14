import 'package:flutter/foundation.dart';

import '../../domain/entities/voice_command.dart';
import '../../domain/repositories/voice_repository.dart';
import '../datasources/speech_data_source.dart';
import '../datasources/ai_data_source.dart';

class VoiceRepositoryImpl implements VoiceRepository {
  final SpeechDataSource speechDataSource;
  final AIDataSource aiDataSource;
  String _lastRecognizedText = '';

  VoiceRepositoryImpl({
    required this.speechDataSource,
    required this.aiDataSource,
  }) {
    // Subscribe to the text stream from the speech data source
    speechDataSource.textStream.listen((text) {
      _lastRecognizedText = text;
    });
  }

  @override
  Future<bool> initialize() async {
    return await speechDataSource.initialize();
  }

  @override
  Future<String> listenForVoiceInput({String? languageCode}) async {
    if (languageCode != null) {
      // Starting a new voice recognition session
      _lastRecognizedText = '';
      try {
        await speechDataSource.listen(localeId: languageCode);
        debugPrint('Started listening with locale: $languageCode');
      } catch (e) {
        debugPrint('Error starting speech recognition: $e');
      }
      return _lastRecognizedText;
    } else {
      // Stopping an ongoing session and returning the result
      try {
        final recognizedText = await speechDataSource.stop();
        debugPrint('Voice recognition stopped, text: $recognizedText');

        // If we got no text from stop but have previously recognized text, use that
        if (recognizedText.isEmpty && _lastRecognizedText.isNotEmpty) {
          debugPrint('Using last recognized text: $_lastRecognizedText');
          return _lastRecognizedText;
        }
        return recognizedText;
      } catch (e) {
        debugPrint('Error stopping speech recognition: $e');
        return _lastRecognizedText;
      }
    }
  }

  @override
  Future<VoiceCommand> processVoiceInput(String input) async {
    // If no input provided, use the last recognized text
    String textToProcess = input.isNotEmpty ? input : _lastRecognizedText;

    if (textToProcess.isEmpty) {
      debugPrint('No text was recognized for processing');
      return VoiceCommand(action: 'error', location: null, date: null);
    }

    // Process the text with AI
    debugPrint('Processing text with AI: $textToProcess');
    try {
      final command = await aiDataSource.processTextToCommand(textToProcess);

      // Debug the processed command
      debugPrint('Processed command: ${command.toJson()}');

      return command;
    } catch (e) {
      debugPrint('Error processing text with AI: $e');
      return VoiceCommand(action: 'error', location: null, date: null);
    }
  }

  @override
  Future<void> speakResponse(String text) async {
    if (text.isNotEmpty) {
      await speechDataSource.speak(text);
    }
  }
}