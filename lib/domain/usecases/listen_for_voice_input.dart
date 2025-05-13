import '../repositories/voice_repository.dart';

class ListenForVoiceInput {
  final VoiceRepository repository;

  ListenForVoiceInput(this.repository);

  Future<String> execute() async {
    return await repository.listenForVoiceInput();
  }
}