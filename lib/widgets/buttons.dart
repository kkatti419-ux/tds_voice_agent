import 'package:flutter/material.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';

class GradientButton extends StatelessWidget {
  final String text;

  const GradientButton({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B6CFF), Color(0xFF8E44AD)],
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(text, style: const TextStyle(color: AgniColors.white)),
    );
  }
}

class OutlineButtonCustom extends StatelessWidget {
  final String text;

  const OutlineButtonCustom({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AgniColors.neutralGrey),
      ),
      child: Text(text),
    );
  }
}
