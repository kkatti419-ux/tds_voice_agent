import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tds_voice_agent/core/constants/app_colors.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const AppButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
