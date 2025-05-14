import '../../data/datasources/ai_data_source.dart';
import '../../data/datasources/speech_data_source.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/repositories/voice_repository_impl.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/repositories/voice_repository.dart';
import '../../domain/usecases/listen_for_voice_input.dart';
import '../../domain/usecases/process_voice_command.dart';
import '../../domain/usecases/speak_response.dart';

// Simple service locator
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  factory ServiceLocator() {
    return _instance;
  }

  ServiceLocator._internal();

  final Map<String, dynamic> _dependencies = {};

  T get<T>() {
    return _dependencies[T.toString()] as T;
  }

  void registerSingleton<T>(T dependency) {
    _dependencies[T.toString()] = dependency;
  }
}

final serviceLocator = ServiceLocator();

Future<void> initDependencies() async {
  // Data sources
  serviceLocator.registerSingleton<SpeechDataSource>(SpeechToTextDataSource());
  serviceLocator.registerSingleton<AIDataSource>(GeminiAIDataSource());

  // Repositories
  serviceLocator.registerSingleton<AIRepository>(
    AIRepositoryImpl(dataSource: serviceLocator.get<AIDataSource>()),
  );

  serviceLocator.registerSingleton<VoiceRepository>(
    VoiceRepositoryImpl(
      speechDataSource: serviceLocator.get<SpeechDataSource>(),
      aiDataSource: serviceLocator.get<AIDataSource>(),
    ),
  );

  // Use cases
  serviceLocator.registerSingleton(
    ListenForVoiceInput(serviceLocator.get<VoiceRepository>()),
  );

  serviceLocator.registerSingleton(
    ProcessVoiceCommand(serviceLocator.get<AIRepository>()),
  );

  serviceLocator.registerSingleton(
    SpeakResponse(serviceLocator.get<VoiceRepository>()),
  );

  // Initialize voice repository
  await serviceLocator.get<VoiceRepository>().initialize();
}