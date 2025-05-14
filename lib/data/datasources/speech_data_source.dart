import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

abstract class SpeechDataSource {
  Future<bool> initialize();

  Future<String> listen({String? localeId});
  Future<String> stop();
  Future<void> speak(String text);
  Stream<String> get textStream;
  void dispose();

  List<LocaleName> get availableLocales;
}

class SpeechToTextDataSource implements SpeechDataSource {
  final SpeechToText _speech;
  final FlutterTts _flutterTts;
  String _recognizedText = '';
  final StreamController<String> _textController = StreamController<
      String>.broadcast();
  List<LocaleName> _availableLocales = [];

  SpeechToTextDataSource()
      : _speech = SpeechToText(),
        _flutterTts = FlutterTts();

  @override
  Future<bool> initialize() async {
    bool available = await _speech.initialize(
      onError: (error) => debugPrint('Speech recognition error: $error'),
      onStatus: (status) => debugPrint('Speech recognition status: $status'),
    );

    if (available) {
      _availableLocales = await _speech.locales();
      debugPrint(
          'Available locales: ${_availableLocales.map((e) => '${e.name} (${e
              .localeId})').join(', ')}');
    }

    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    return available;
  }

  @override
  Future<String> listen({String? localeId}) async {
    _recognizedText = '';

    if (!_speech.isAvailable) {
      return 'Speech recognition not available';
    }

    // Make sure we're not already listening
    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Select the best locale - use provided, or Tamil, or default to English
    String selectedLocale = localeId ?? 'ta-IN';

    // Check if the selected locale is available, fallback to English if not
    bool localeFound = _availableLocales.any((locale) =>
    locale.localeId == selectedLocale);
    if (!localeFound) {
      debugPrint('Locale $selectedLocale not found, falling back to en_US');
      selectedLocale = 'en_US';
    }

    debugPrint('Starting speech recognition with locale: $selectedLocale');

    try {
      await _speech.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          _textController.add(_recognizedText);
          debugPrint('Recognized text: $_recognizedText');
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: selectedLocale,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        onSoundLevelChange: (level) {
          // This helps keep the recognition alive
          debugPrint('Sound level: $level');
        },
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      rethrow;
    }

    return _recognizedText;
  }

  @override
  Future<String> stop() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
        debugPrint('Speech recognition stopped with text: $_recognizedText');
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        debugPrint('Speech recognition was not active');
      }
      return _recognizedText;
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
      return _recognizedText;
    }
  }

  @override
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Stream<String> get textStream => _textController.stream;

  @override
  void dispose() {
    _textController.close();
  }

  @override
  List<LocaleName> get availableLocales => _availableLocales;
}