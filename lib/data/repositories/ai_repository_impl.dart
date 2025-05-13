import '../../domain/entities/voice_command.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_data_source.dart';

class AIRepositoryImpl implements AIRepository {
  final AIDataSource dataSource;

  AIRepositoryImpl({required this.dataSource});

  @override
  Future<VoiceCommand> processTextToCommand(String text) async {
    return await dataSource.processTextToCommand(text);
  }
}