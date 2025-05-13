import 'package:flutter/material.dart';
import '../state/voice_assistant_state.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class ResponseDisplay extends StatelessWidget {
  const ResponseDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<VoiceAssistantState>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Voice recording status
          Text(
            state.isListening ? 'Listening...' : 'Press and hold to speak',
            style: TextStyle(
              fontSize: 18,
              color: state.isListening ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(height: 20),

          // Recognized text
          if (state.recognizedText.isNotEmpty) ...[
            const Text(
                'You said:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(state.recognizedText, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
          ],

          // Loading indicator
          if (state.isLoading)
            const CircularProgressIndicator(),

          // Error message
          if (state.errorMessage.isNotEmpty)
            Text(
              state.errorMessage,
              style: const TextStyle(color: Colors.red),
            ),

          // JSON response
          if (state.command != null) ...[
            const Text('Server command:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getFormattedJson(state.command!),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getFormattedJson(dynamic command) {
    final Map<String, dynamic> jsonData = {
      'action': command.action,
      'location': command.location,
      'date': command.date,
    };
    return const JsonEncoder.withIndent('  ').convert(jsonData);
  }
}