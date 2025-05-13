import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract class SpeechDataSource {
  Future<bool> initialize();

  Future<String> listen();

  Future<void> speak(String text);

  Future<void> stop();
}

class SpeechToTextDataSource implements SpeechDataSource {
  final SpeechToText _speech;
  final FlutterTts _flutterTts;
  String _recognizedText = '';

  SpeechToTextDataSource()
      :
        _speech = SpeechToText(),
        _flutterTts = FlutterTts();

  @override
  Future<bool> initialize() async {
    bool available = await _speech.initialize(
      onError: (error) => debugPrint('Speech recognition error: $error'),
      onStatus: (status) => debugPrint('Speech recognition status: $status'),
    );
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    return available;
  }

  @override
  Future<String> listen() async {
    _recognizedText = '';

    if (!_speech.isAvailable) {
      return 'Speech recognition not available';
    }

    await _speech.listen(
      onResult: (result) {
        _recognizedText = result.recognizedWords;
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      localeId: 'en_US',
    );

    // This doesn't return the text immediately, but the _speech.listen is non-blocking
    // so we need to wait for the completion in the UI layer and get the text 
    // through the state management
    return _recognizedText;
  }

  @override
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _speech.stop();
  }
}