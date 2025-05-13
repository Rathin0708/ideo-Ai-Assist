import '../entities/voice_command.dart';
import '../repositories/ai_repository.dart';

class ProcessVoiceCommand {
  final AIRepository repository;

  ProcessVoiceCommand(this.repository);

  Future<VoiceCommand> execute(String text) async {
    return await repository.processTextToCommand(text);
  }
}