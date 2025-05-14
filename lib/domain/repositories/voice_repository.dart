import '../entities/voice_command.dart';

abstract class VoiceRepository {
  Future<bool> initialize();

  Future<String> listenForVoiceInput({String? languageCode});

  Future<VoiceCommand> processVoiceInput(String input);

  Future<void> speakResponse(String text);
}