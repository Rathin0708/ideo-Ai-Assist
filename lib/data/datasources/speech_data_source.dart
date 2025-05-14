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
  String _lastPartialText = '';
  final StreamController<String> _textController = StreamController<
      String>.broadcast();
  List<LocaleName> _availableLocales = [];
  Timer? _keepAliveTimer;
  Timer? _inactivityTimer;

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
    _lastPartialText = '';

    if (!_speech.isAvailable) {
      return 'Speech recognition not available';
    }

    // Make sure we're not already listening
    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final languageToLocale = {
      'en': 'en-US',
      'ta': 'ta-IN',
      'hi': 'hi-IN',
      'te': 'te-IN',
      'ml': 'ml-IN',
      'kn': 'kn-IN',
    };

    String selectedLocale = localeId ?? 'ta-IN';

    if (localeId != null && localeId.length == 2) {
      selectedLocale = languageToLocale[localeId] ?? 'en-US';
    }

    // Safety check for Tamil - since many devices don't support it
    if (selectedLocale == 'ta-IN') {
      // First check if Tamil is actually in available locales
      bool hasTamil = _availableLocales.any((locale) =>
      locale.localeId.toLowerCase().startsWith('ta') ||
          locale.name.toLowerCase().contains('tamil'));

      if (!hasTamil) {
        debugPrint(
            'Tamil not found in available locales, defaulting to English');
        // Find best English locale
        for (var locale in _availableLocales) {
          if (locale.localeId.toLowerCase().startsWith('en')) {
            selectedLocale = locale.localeId;
            debugPrint('Found English locale: $selectedLocale');
            break;
          }
        }
      }
    }

    bool localeFound = _availableLocales.any((locale) =>
        locale.localeId.startsWith(selectedLocale.split('-')[0]));
    if (!localeFound) {
      debugPrint('Locale $selectedLocale not found, trying to find best match');

      // Always fall back to English if Tamil is not available
      debugPrint('Tamil locale not available, falling back to English (en-US)');
      selectedLocale = 'en-US';

      // Find the English locale
      final englishLocale = _availableLocales.firstWhere(
              (locale) => locale.localeId.toLowerCase().contains('en'),
          orElse: () => _availableLocales.first
      );

      selectedLocale = englishLocale.localeId;
      debugPrint('Selected best match locale: $selectedLocale');
    }

    final languageCode = selectedLocale
        .split('-')
        .first
        .toLowerCase();

    debugPrint('Starting speech recognition with locale: $selectedLocale');

    try {
      await _speech.listen(
        onResult: (result) {
          final text = result.recognizedWords;
          // Stream partial results immediately for real-time display
          if (result.finalResult) {
            _recognizedText = text;
            _textController.add('${languageCode}:$_recognizedText');
            debugPrint('Final recognized text: $_recognizedText');
          } else {
            _lastPartialText = text;
            _textController.add('partial:${languageCode}:$text');
            debugPrint('Partial recognized text: $text');
          }
        },
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(seconds: 10),
        partialResults: true,
        localeId: selectedLocale,
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
        onSoundLevelChange: (level) {
          if (level > -1.0) {
            _resetInactivityTimer();
          }
        },
      );

      _startKeepAliveTimer();
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
        if (_recognizedText.isEmpty && _lastPartialText.isNotEmpty) {
          _recognizedText = _lastPartialText;
          debugPrint('Using last partial text as final: $_recognizedText');
          // For Tamil-specific post-processing (common recognition issues)
          if (_recognizedText.contains('rupees') ||
              _recognizedText.contains('Rs') ||
              _recognizedText.contains('rs') ||
              _recognizedText.contains('ரூபாய்')) {
            debugPrint('Found currency references, treating as transaction');
            _recognizedText = _postProcessTransactionText(_recognizedText);
          }
        }
      } else {
        debugPrint('Speech recognition was not active');
      }
      return _recognizedText;
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
      return _recognizedText;
    }
  }

  String _postProcessTransactionText(String text) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains('ரூபாய்') || lowerText.contains('ரூ')) {
      debugPrint('Processing Tamil transaction text');

      if (!lowerText.contains('வாங்க')) {
        return 'வாங்க $text';
      }
      return text;
    }

    if ((lowerText.contains('buy') || lowerText.contains('bought')) &&
        !lowerText.contains('today')) {
      return 'today $text';
    }

    if (lowerText.contains('by') && !lowerText.contains('buy')) {
      return text.replaceAll('by', 'buy');
    }

    if ((lowerText.contains('rupees') || lowerText.contains('rs')) &&
        !lowerText.contains('buy') && !lowerText.contains('bought')) {
      return 'buy $text';
    }

    return text;
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
    _cancelKeepAliveTimer();
    if (_speech.isListening) {
      _speech.stop();
    }
  }

  @override
  List<LocaleName> get availableLocales => _availableLocales;

  String _getBestLocaleMatch(String languageCode) {
    for (var locale in _availableLocales) {
      if (locale.localeId == languageCode) {
        return locale.localeId;
      }
    }

    for (var locale in _availableLocales) {
      if (locale.localeId.startsWith(languageCode.split('-')[0])) {
        return locale.localeId;
      }
    }

    return 'en-US';
  }

  void _startKeepAliveTimer() {
    _cancelKeepAliveTimer();

    _keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_speech.isListening) {
        debugPrint('Keep-alive ping for speech recognition');
      } else {
        _cancelKeepAliveTimer();
      }
    });

    _resetInactivityTimer();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 30), () {
      if (_speech.isListening) {
        debugPrint('Inactivity detected, but continuing to listen');
      }
    });
  }

  void _cancelKeepAliveTimer() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }
}