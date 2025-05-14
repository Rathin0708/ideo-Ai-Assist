import 'package:flutter/material.dart';
import '../state/voice_assistant_state.dart';
import 'package:provider/provider.dart';

class VoiceButton extends StatefulWidget {
  const VoiceButton({super.key});

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with SingleTickerProviderStateMixin {
  bool isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<VoiceAssistantState>(context);
    final isProcessing = state.isProcessing;
    final isListening = state.isListening;

    return Material(
      elevation: 8,
      shadowColor: Colors.deepPurpleAccent.withOpacity(0.5),
      shape: const CircleBorder(),
      child: InkWell(
        onTapDown: (_) {
          if (!isProcessing) {
            setState(() {
              isPressed = true;
            });
            _animationController.forward();
            // Add a small delay before starting to listen
            Future.delayed(const Duration(milliseconds: 100), () {
              if (isPressed) {
                state.startListening();
              }
            });
          }
        },
        onTapUp: (_) {
          if (isPressed) {
            setState(() {
              isPressed = false;
            });
            _animationController.reverse();
            state.stopListening();
          }
        },
        onTapCancel: () {
          if (isPressed) {
            setState(() {
              isPressed = false;
            });
            _animationController.reverse();
            state.stopListening();
          }
        },
        customBorder: const CircleBorder(),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color:
                      isProcessing
                          ? Colors.amber
                          : isListening
                          ? Colors.red
                          : Colors.deepPurple,
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
                      isProcessing
                          ? Icons.hourglass_top
                          : isListening
                          ? Icons.mic
                          : Icons.mic_none,
                      size: 40,
                      color: Colors.white,
                    ),
                    Text(
                      isProcessing
                          ? 'Processing...'
                          : isListening
                          ? 'Release when done'
                          : 'Hold to speak',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}