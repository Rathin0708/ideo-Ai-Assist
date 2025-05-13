import '../../domain/entities/voice_command.dart';
import '../../domain/repositories/voice_repository.dart';
import '../datasources/speech_data_source.dart';
import '../datasources/ai_data_source.dart';

class VoiceRepositoryImpl implements VoiceRepository {
  final SpeechDataSource speechDataSource;
  final AIDataSource aiDataSource;

  VoiceRepositoryImpl({
    required this.speechDataSource,
    required this.aiDataSource,
  });

  @override
  Future<bool> initialize() async {
    return await speechDataSource.initialize();
  }

  @override
  Future<String> listenForVoiceInput() async {
    await speechDataSource.listen();
    // Listen is non-blocking and updates internally, so we return empty string here
    // and will get the actual text when stopping
    return '';
  }

  @override
  Future<VoiceCommand> processVoiceInput(String input) async {
    if (input.isEmpty) {
      // If input is empty, we likely came from listenForVoiceInput and need to stop first
      await speechDataSource.stop();
    }

    // Use the text from the speech recognition
    final command = await aiDataSource.processTextToCommand(input);
    return command;
  }

  @override
  Future<void> speakResponse(String text) async {
    await speechDataSource.speak(text);
  }
}