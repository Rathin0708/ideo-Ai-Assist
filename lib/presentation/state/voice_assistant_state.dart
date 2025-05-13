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

  Future<void> startListening() async {
    _isListening = true;
    _recognizedText = '';
    _command = null;
    _errorMessage = '';
    notifyListeners();

    try {
      await _listenForVoiceInput.execute();
    } catch (e) {
      _errorMessage = 'Failed to start listening: $e';
    }

    notifyListeners();
  }

  Future<void> stopListening() async {
    try {
      _isListening = false;
      _isLoading = true;
      notifyListeners();

      // Process the voice input
      _command = await _processVoiceCommand.execute(_recognizedText);

      // Generate confirmation message
      final confirmationMessage = _generateConfirmationMessage(_command!);

      // Speak the confirmation
      await _speakResponse.execute(confirmationMessage);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error processing voice command: $e';
      notifyListeners();
    }
  }

  void updateRecognizedText(String text) {
    _recognizedText = text;
    notifyListeners();
  }

  String _generateConfirmationMessage(VoiceCommand command) {
    return "I'll ${command.action} at ${command.location ??
        'unspecified location'} on ${command.date ?? 'unspecified date'}";
  }
}