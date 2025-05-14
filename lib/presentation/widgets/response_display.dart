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
            state.isListening
                ? 'Listening...'
                : state.isProcessing
                ? 'Processing...'
                : 'Press and hold to speak',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: state.isListening
                  ? Colors.green
                  : state.isProcessing
                  ? Colors.orange
                  : Colors.grey,
            ),
          ),
          const SizedBox(height: 20),

          // Recognized text
          if (state.recognizedText.isNotEmpty) ...[
            const Text(
                'You said:', style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              width: double.infinity,
              child: Text(
                  state.recognizedText,
                  style: const TextStyle(fontSize: 16)
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Loading indicator
          if (state.isProcessing) ...[
            const SizedBox(height: 10),
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            Text(
              'Converting speech to structured data...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],

          // Response message
          if (state.responseMessage.isNotEmpty && !state.isProcessing) ...[
            const Text('Response:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              width: double.infinity,
              child: Text(
                state.responseMessage,
                style: TextStyle(fontSize: 16, color: Colors.blue[800]),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Error message
          if (state.errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              width: double.infinity,
              child: Text(
                state.errorMessage,
                style: TextStyle(color: Colors.red[800]),
              ),
            ),

          // JSON response
          if (state.command != null && !state.isProcessing) ...[
            const SizedBox(height: 20),
            const Text('Server JSON:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              width: double.infinity,
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