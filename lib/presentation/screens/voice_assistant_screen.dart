import 'package:flutter/material.dart';
import '../widgets/voice_button.dart';
import '../widgets/response_display.dart';
import '../state/voice_assistant_state.dart';
import 'package:provider/provider.dart';

class VoiceAssistantScreen extends StatelessWidget {
  const VoiceAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Assistant'),
        centerTitle: true,
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        actions: [
          _buildLanguageMenu(context),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: const ResponseDisplay(),
          ),
        ],
      ),
      floatingActionButton: const VoiceButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildLanguageMenu(BuildContext context) {
    final languages = {
      'en-US': 'English',
      'ta-IN': 'Tamil',
      'hi-IN': 'Hindi',
    };

    final state = Provider.of<VoiceAssistantState>(context, listen: false);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.language),
      tooltip: 'Select Language',
      onSelected: (String langCode) {
        state.setLanguage(langCode);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Language set to ${languages[langCode]}'))
        );
      },
      itemBuilder: (context) =>
          languages.entries
              .map((entry) =>
              PopupMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              ))
          .toList(),
    );
  }
}