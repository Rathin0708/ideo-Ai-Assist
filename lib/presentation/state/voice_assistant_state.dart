import 'package:flutter/material.dart';
import '../../domain/entities/voice_command.dart';
import '../../domain/usecases/listen_for_voice_input.dart';
import '../../domain/usecases/process_voice_command.dart';
import '../../domain/usecases/speak_response.dart';

class VoiceAssistantState extends ChangeNotifier {
  final ListenForVoiceInput _listenForVoiceInput;
  final ProcessVoiceCommand _processVoiceCommand;
  final SpeakResponse _speakResponse;

  bool _isListening = false;
  String _recognizedText = '';
  VoiceCommand? _command;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isProcessing = false;
  String _responseMessage = '';
  String _selectedLanguage = 'en-US';

  VoiceAssistantState({
    required ListenForVoiceInput listenForVoiceInput,
    required ProcessVoiceCommand processVoiceCommand,
    required SpeakResponse speakResponse,
  })
      : _listenForVoiceInput = listenForVoiceInput,
        _processVoiceCommand = processVoiceCommand,
        _speakResponse = speakResponse;

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;
  VoiceCommand? get command => _command;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isProcessing => _isProcessing;
  String get responseMessage => _responseMessage;

  String get selectedLanguage => _selectedLanguage;

  void setLanguage(String languageCode) {
    _selectedLanguage = languageCode;
    notifyListeners();
  }

  Future<void> startListening() async {
    if (_isProcessing) return;

    _isListening = true;
    _recognizedText = '';
    _command = null;
    _errorMessage = '';
    _responseMessage = '';
    notifyListeners();

    try {
      // Start listening with selected language
      await _listenForVoiceInput.execute(languageCode: _selectedLanguage);
      debugPrint('Successfully started listening');
    } catch (e) {
      _errorMessage = 'Failed to start listening: $e';
      _isListening = false;
      notifyListeners();
      debugPrint('Error starting listening: $e');
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    debugPrint('Stopping listening...');
    _isListening = false;
    notifyListeners();

    try {
      _isProcessing = true;
      notifyListeners();

      // Get the recognized text by stopping speech recognition
      final recognizedText = await _listenForVoiceInput.execute();
      _recognizedText = recognizedText;

      debugPrint('Recognized text after stopping: $_recognizedText');

      if (_recognizedText.isEmpty || _recognizedText
          .trim()
          .isEmpty) {
        _isProcessing = false;
        _responseMessage = "I didn't catch that. Please try speaking again.";
        notifyListeners();
        await _speakResponse.execute(_responseMessage);
        return;
      }

      debugPrint('Final recognized text: $_recognizedText');

      // Process the voice input with AI
      final input = await _processVoiceCommand.execute(_recognizedText);
      _command = input;

      if (_command != null && _command!.action != 'error' &&
          _command!.action != 'unknown') {
        // Generate confirmation message based on the command
        final confirmationMessage = _generateConfirmationMessage(_command!);
        _responseMessage = confirmationMessage;

        debugPrint('Command processed: ${_command!.action}');
        debugPrint('Response: $_responseMessage');

        // Speak the confirmation
        await _speakResponse.execute(confirmationMessage);
      } else {
        _responseMessage = "Sorry, I couldn't understand that request.";
        await _speakResponse.execute(_responseMessage);
      }
    } catch (e) {
      _errorMessage = 'Error processing voice command: $e';
      _responseMessage = "Sorry, there was an error processing your request.";
      debugPrint('Error in voice processing: $e');
      await _speakResponse.execute(_responseMessage);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void updateRecognizedText(String text) {
    _recognizedText = text;
    notifyListeners();
  }

  String _generateConfirmationMessage(VoiceCommand command) {
    final StringBuffer message = StringBuffer(
        "I've processed your request to ${command.action}");

    if (command.location != null && command.location!.isNotEmpty) {
      message.write(" at ${command.location}");
    }

    if (command.date != null && command.date!.isNotEmpty) {
      message.write(" on ${command.date}");
    }

    return message.toString();
  }
}