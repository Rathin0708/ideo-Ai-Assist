import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/injection/injection_container.dart' as di;
import 'presentation/state/voice_assistant_state.dart';
import 'presentation/screens/voice_assistant_screen.dart';
import 'domain/usecases/listen_for_voice_input.dart';
import 'domain/usecases/process_voice_command.dart';
import 'domain/usecases/speak_response.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies
  await di.initDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          VoiceAssistantState(
            listenForVoiceInput: di.serviceLocator.get<ListenForVoiceInput>(),
            processVoiceCommand: di.serviceLocator.get<ProcessVoiceCommand>(),
            speakResponse: di.serviceLocator.get<SpeakResponse>(),
      ),
      child: MaterialApp(
        title: 'Voice Assistant',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const VoiceAssistantScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}