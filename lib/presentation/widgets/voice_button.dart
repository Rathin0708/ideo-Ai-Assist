import 'package:flutter/material.dart';
import '../state/voice_assistant_state.dart';
import 'package:provider/provider.dart';

class VoiceButton extends StatelessWidget {
  const VoiceButton({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<VoiceAssistantState>(context);

    return GestureDetector(
      onLongPressStart: (_) => state.startListening(),
      onLongPressEnd: (_) => state.stopListening(),
      child: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: state.isListening ? Colors.red : Colors.deepPurple,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 3,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          state.isListening ? Icons.mic : Icons.mic_none,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }
}