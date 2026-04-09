import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';
import 'package:tds_voice_agent/domain/entities/agni_content.dart';
import 'package:tds_voice_agent/widgets/feature/feature_card.dart';

class FeaturesSection extends StatelessWidget {
  final List<FeatureItem> features;
  final bool isDark;

  const FeaturesSection({
    super.key,
    required this.features,
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
          _sectionTag(),
          const SizedBox(height: 18),

          _sectionTitle(),
          const SizedBox(height: 16),

          Text(
            'Built from day one for the languages that matter most — not as an afterthought.',
            style: TextStyle(fontSize: 16, color: text3Color, height: 1.6),
          ),

          const SizedBox(height: 40),

          /// 🔥 Responsive Grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: features.map((f) {
              return SizedBox(
                width: _getItemWidth(width),
                child: FeatureCard(item: f, isDark: isDark),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  double _getItemWidth(double width) {
    if (width > 900) return (width - 104) / 3; // desktop
    if (width > 600) return (width - 64) / 2; // tablet
    return width; // mobile
  }

  Widget _sectionTag() {
    return const Text(
      "Why Technodysis",
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _sectionTitle() {
    return Text(
      "Not translated. Native.",
      style: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
