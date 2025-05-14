import 'package:flutter/material.dart';
import '../state/voice_assistant_state.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class VoiceButton extends StatefulWidget {
  const VoiceButton({Key? key}) : super(key: key);

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with SingleTickerProviderStateMixin {
  bool isPressed = false;
  late AnimationController _pulseController;
  int _recordingDuration = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<VoiceAssistantState>(context);
    final isProcessing = state.isProcessing;
    final isListening = state.isListening;
    final isAccuracyMode = state.isAccuracyMode;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (isListening)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 120 + (_pulseController.value * 40),
                height: 120 + (_pulseController.value * 40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withOpacity(
                        0.6 * (1 - _pulseController.value)),
                    width: 2,
                  ),
                ),
              );
            },
          ),

        Material(
          elevation: 8,
          shadowColor: Colors.deepPurpleAccent.withOpacity(0.5),
          shape: const CircleBorder(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) {
              if (!isProcessing) {
                setState(() {
                  isPressed = true;
                });
                state.startListening();
                _startRecordingTimer();
              }
            },
            onLongPress: () {
              // Keep listening - don't do anything on long press
              // This ensures continuous listening while pressed
            },
            onLongPressEnd: (_) {
              if (isPressed) {
                setState(() {
                  isPressed = false;
                });
                state.stopListening();
                _stopRecordingTimer();
              }
            },
            onTapUp: (_) {
              if (isPressed) {
                setState(() {
                  isPressed = false;
                });
                state.stopListening();
                _stopRecordingTimer();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isPressed ? 85 : 80,
              height: isPressed ? 85 : 80,
              decoration: BoxDecoration(
                color: _getButtonColor(
                    isProcessing, isListening, isAccuracyMode),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getButtonIcon(isProcessing, isListening, isAccuracyMode),
                    size: 40,
                    color: Colors.white,
                  ),
                  Text(
                    _getButtonText(isProcessing, isListening, isAccuracyMode),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                  if (isListening && _recordingDuration > 0)
                    Text(
                      _formatDuration(_recordingDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startRecordingTimer() {
    _recordingDuration = 0;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration++;
      });
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingDuration = 0;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds
        .toString()
        .padLeft(2, '0')}';
  }

  Color _getButtonColor(bool isProcessing, bool isListening,
      bool isAccuracyMode) {
    if (isProcessing) return Colors.amber;
    if (isListening) return Colors.red;
    if (isAccuracyMode) return Colors.green.shade600;
    return Colors.deepPurple;
  }

  IconData _getButtonIcon(bool isProcessing, bool isListening,
      bool isAccuracyMode) {
    if (isProcessing) return Icons.hourglass_top;
    if (isListening) return Icons.mic;
    if (isAccuracyMode) return Icons.mic;
    return Icons.mic_none;
  }

  String _getButtonText(bool isProcessing, bool isListening,
      bool isAccuracyMode) {
    if (isProcessing) return 'Processing...';
    if (isListening) return 'Recording...';
    if (isAccuracyMode) return 'AI Enhanced';
    return 'Press & Hold';
  }
}