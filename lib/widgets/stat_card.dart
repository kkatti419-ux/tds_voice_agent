import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String value;
  final String description;
  final bool isDark;

  const StatCard({
    super.key,
    required this.value,
    required this.description,
    required this.isDark,
  });

  Color get text3Color => isDark ? Colors.white60 : Colors.black54;

  final LinearGradient gradText = const LinearGradient(
    colors: [Color(0xFF5B6CFF), Color(0xFF8E44AD)],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          // 🔥 Top gradient line
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5B6CFF), Color(0xFF8E44AD)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🎨 Gradient number
                ShaderMask(
                  shaderCallback: (bounds) => gradText.createShader(bounds),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: text3Color,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
