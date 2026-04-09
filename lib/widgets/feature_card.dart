import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tds_voice_agent/domain/entities/agni_content.dart';

class FeatureCard extends StatelessWidget {
  final FeatureItem item;
  final bool isDark;

  const FeatureCard({super.key, required this.item, required this.isDark});

  Color get textColor => isDark ? Colors.white : Colors.black;
  Color get text3Color => isDark ? Colors.white60 : Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Icon box
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.blue.withOpacity(0.12),
                        Colors.green.withOpacity(0.10),
                      ]
                    : [
                        Colors.blue.withOpacity(0.10),
                        Colors.green.withOpacity(0.10),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(item.icon, style: const TextStyle(fontSize: 24)),
            ),
          ),

          const SizedBox(height: 16),

          /// 🔹 Title
          Text(
            item.title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),

          const SizedBox(height: 8),

          /// 🔹 Description
          Text(
            item.description,
            style: TextStyle(fontSize: 14, color: text3Color, height: 1.6),
          ),

          const SizedBox(height: 16),

          /// 🔹 Stat
          Text(
            item.stat,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
