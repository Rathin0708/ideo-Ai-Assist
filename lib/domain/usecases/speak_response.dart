import '../repositories/voice_repository.dart';

class SpeakResponse {
  final VoiceRepository repository;

  SpeakResponse(this.repository);

  Future<void> execute(String text) async {
    await repository.speakResponse(text);
  }
}