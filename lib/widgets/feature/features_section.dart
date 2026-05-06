import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';
import 'package:tds_voice_agent/model/agni_content.dart';
import 'package:tds_voice_agent/widgets/feature/feature_card.dart';

class FeaturesSection extends StatelessWidget {
  final AgniContent content;
  final bool isDark;

  const FeaturesSection({
    super.key,
    required this.content,
    required this.isDark,
  });

  Color get textColor => isDark ? AgniColors.white : AgniColors.black;
  Color get text3Color => isDark ? AgniColors.white60 : AgniColors.black54;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.featuresSectionTag,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 18),

          Text(
            content.featuresSectionTitle,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            content.featuresSectionBlurb,
            style: TextStyle(fontSize: 16, color: text3Color, height: 1.6),
          ),

          const SizedBox(height: 40),

          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: content.features.map((f) {
              final w = _getItemWidth(width);
              return SizedBox(
                width: w,
                child: FeatureCard(item: f, isDark: isDark),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  double _getItemWidth(double width) {
    if (width > 900) return (width - 104) / 3;
    if (width > 600) return (width - 64) / 2;
    return width;
  }
}
