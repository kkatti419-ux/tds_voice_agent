import 'package:flutter/material.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';

class MicAnimation extends StatelessWidget {
  final bool isListening;
  final double amplitudeDb;
  final bool isAgentSpeaking;

  const MicAnimation({
    super.key,
    required this.isListening,
    required this.amplitudeDb,
    required this.isAgentSpeaking,
  });
  

  @override
  Widget build(BuildContext context) {
    // Map negative dBFS range roughly (-60..-20) to 0..1.
    final level = ((amplitudeDb - -60) / 40).clamp(0.0, 1.0);
    final bool active = isListening || isAgentSpeaking;
    final double size = active
        ? (80 + (level * 80))
        : 80;
    final Color glowColor =
        isAgentSpeaking ? AgniColors.signalLimeAccent : AgniColors.signalLime;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? glowColor.withOpacity(0.9) : AgniColors.neutralGrey,
      ),
      child: Icon(
        Icons.mic,
        color: AgniColors.white,
        size: isAgentSpeaking ? 44 : 40,
      ),
    );
  }
}