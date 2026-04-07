import 'package:flutter/material.dart';

class MicAnimation extends StatelessWidget {
  final bool isListening;

  const MicAnimation({super.key, required this.isListening});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: isListening ? 120 : 80,
      width: isListening ? 120 : 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isListening ? Colors.blue : Colors.grey,
      ),
      child: const Icon(Icons.mic, color: Colors.white, size: 40),
    );
  }
}