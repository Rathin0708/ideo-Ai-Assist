import '../entities/voice_command.dart';

abstract class AIRepository {
  Future<VoiceCommand> processTextToCommand(String text, {String? commandMode});
}