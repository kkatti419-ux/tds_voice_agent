import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';
import 'package:tds_voice_agent/model/agni_content.dart';

class FeatureCard extends StatelessWidget {
  final FeatureItem item;
  final bool isDark;

  const FeatureCard({super.key, required this.item, required this.isDark});

  Color get textColor => isDark ? AgniColors.white : AgniColors.black;
  Color get text3Color => isDark ? AgniColors.white60 : AgniColors.black54;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AgniColors.white.withOpacity(0.05) : AgniColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AgniColors.neutralGrey.withOpacity(0.2)),
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
                        AgniColors.oceanBright.withOpacity(0.12),
                        AgniColors.forestBright.withOpacity(0.10),
                      ]
                    : [
                        AgniColors.oceanBright.withOpacity(0.10),
                        AgniColors.forestBright.withOpacity(0.10),
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

          /// 🔹 Description (multi-line; no fixed parent height)
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
              color: AgniColors.forestMid,
            ),
          ),
        ],
      ),
    );
  }
}
