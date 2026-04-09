import 'package:flutter/material.dart';

class LanguagePill extends StatelessWidget {
  final String label;
  final String type; // 'ocean' | 'forest' | default
  final bool isDark;

  const LanguagePill({
    super.key,
    required this.label,
    required this.type,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Gradient? gradient;

    if (type == 'ocean') {
      gradient = const LinearGradient(
        colors: [Color(0xFF5B6CFF), Color(0xFF4EB3D3)],
      );
    } else if (type == 'forest') {
      gradient = const LinearGradient(
        colors: [Color(0xFF52B788), Color(0xFF74C69D)],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null
            ? (isDark
                  ? const Color(0xFF0E2D4A).withOpacity(0.55)
                  : Colors.white.withOpacity(0.65))
            : null,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: gradient != null
              ? Colors.transparent
              : (isDark
                    ? Colors.blue.withOpacity(0.12)
                    : Colors.white.withOpacity(0.85)),
        ),
        boxShadow: gradient != null
            ? [
                BoxShadow(
                  color: (type == 'ocean' ? Colors.blue : Colors.green)
                      .withOpacity(0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: gradient != null
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }
}
