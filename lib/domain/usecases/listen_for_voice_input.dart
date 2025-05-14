import '../repositories/voice_repository.dart';

class ListenForVoiceInput {
  final VoiceRepository repository;

  ListenForVoiceInput(this.repository);

  Future<String> execute({String? languageCode}) async {
    return await repository.listenForVoiceInput(languageCode: languageCode);
  }
}