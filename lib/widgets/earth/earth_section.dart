// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:tds_voice_agent/core/agni_colors.dart';
// import 'package:tds_voice_agent/theme/app_typography.dart';
// import 'package:tds_voice_agent/widgets/cta_section.dart';
// import 'package:tds_voice_agent/widgets/earth_global_container.dart';

// class EarthSection extends StatefulWidget {
//   final List<LangItem> langPills;
//   final bool isDark;

//   const EarthSection({
//     super.key,
//     required this.langPills,
//     required this.isDark,
//   });

//   @override
//   State<EarthSection> createState() => _EarthSectionState();
// }

// class LangItem {
//   final String label;
//   final String type;

//   LangItem(this.label, this.type);

//   @override
//   String toString() => label;
// }

// class _EarthSectionState extends State<EarthSection>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _globeController;

//   @override
//   void initState() {
//     super.initState();
//     _globeController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 10),
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     _globeController.dispose();
//     super.dispose();
//   }

//   Color get textColor => widget.isDark ? Colors.white : Colors.black;
//   Color get text3Color => widget.isDark ? Colors.white60 : Colors.black54;

//   final LinearGradient gradText = const LinearGradient(
//     colors: [Color(0xFF5B6CFF), Color(0xFF8E44AD)],
//   );

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
//       child: Column(
//         children: [
//           const Text(
//             "Global delivery",
//             style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
//           ),

//           const SizedBox(height: 18),

//           /// 🔥 Title
//           RichText(
//             textAlign: TextAlign.center,
//             text: TextSpan(
//               style: GoogleFonts.playfairDisplay(
//                 fontSize: 32,
//                 fontWeight: FontWeight.w900,
//                 height: 1.2,
//                 color: textColor,
//               ),
//               children: [
//                  TextSpan(text: "Built in Bangalore.\nDelivered across ",style: AppTypography.bodyMedium(color: AgniColors.darkBg)),
//                 WidgetSpan(
//                   child: ShaderMask(
//                     shaderCallback: (b) => gradText.createShader(b),
//                     child: Text(
//                       'the world.',
//                       style: GoogleFonts.playfairDisplay(
//                         fontSize: 32,
//                         fontWeight: FontWeight.w900,
//                         fontStyle: FontStyle.italic,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 16),

//           Text(
//             "Technodysis builds from Bangalore and delivers globally.",
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 14, color: text3Color),
//           ),

//           const SizedBox(height: 40),

//           /// 🌍 Globe
//           AnimatedBuilder(
//             animation: _globeController,
//             builder: (_, __) {
//               return Column(
//                 children: [
//                   CustomPaint(
//                     size: const Size(260, 260),
//                     painter: EarthGlobePainter(
//                       t: _globeController.value,
//                       isDark: widget.isDark,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                 ],
//               );
//             },
//           ),

//           const SizedBox(height: 32),

//           /// 🌐 Language pills
//           Wrap(
//             spacing: 10,
//             runSpacing: 10,
//             alignment: WrapAlignment.center,
//             children: widget.langPills
//                 .map(
//                   (p) => LanguagePill(
//                     label: p.toString(),
//                     isDark: widget.isDark,
//                     type: '',
//                   ),
//                 )
//                 .toList(),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';
import 'package:tds_voice_agent/globe/globe_page.dart';
import 'package:tds_voice_agent/theme/app_typography.dart';
import 'package:tds_voice_agent/widgets/cta_section.dart';

class EarthSection extends StatefulWidget {
  final List<LangItem> langPills;
  final bool isDark;

  const EarthSection({
    super.key,
    required this.langPills,
    required this.isDark,
  });

  @override
  State<EarthSection> createState() => _EarthSectionState();
}

class LangItem {
  final String label;
  final String type;

  LangItem(this.label, this.type);

  @override
  String toString() => label;
}

class _EarthSectionState extends State<EarthSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _globeController;

  /// Square iframe globe: scale with section width (mobile vs tablet vs desktop).
  double _globeSideForLayoutWidth(double maxWidth) {
    final w = maxWidth.isFinite && maxWidth > 0 ? maxWidth : 800.0;
    if (w < 420) {
      return math.max(220, w * 0.94);
    }
    if (w < 720) {
      return math.min(w * 0.88, 480);
    }
    if (w < 1100) {
      return math.min(w * 0.58, 540);
    }
    return math.min(w * 0.45, 560);
  }

  @override
  void initState() {
    super.initState();
    _globeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _globeController.dispose();
    super.dispose();
  }

  bool get isDark => widget.isDark;

  Color get titleColor => isDark ? AgniColors.white : AgniColors.black;

  Color get subtitleColor => isDark ? AgniColors.white70 : AgniColors.black54;

  LinearGradient get accentGradient =>
      const LinearGradient(colors: [Color(0xFF5B6CFF), Color(0xFF8E44AD)]);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          /// SECTION LABEL
          Text(
            "GLOBAL DELIVERY",
            style: AppTypography.bodyMedium(color: subtitleColor).copyWith(
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 22),

          /// HERO TITLE
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.playfairDisplay(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                height: 1.2,
                color: titleColor,
              ),
              children: [
                const TextSpan(text: "Built in Bangalore.\nDelivered across "),

                WidgetSpan(
                  child: ShaderMask(
                    shaderCallback: (b) => accentGradient.createShader(b),
                    child: Text(
                      "the world.",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AgniColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// SUBTITLE
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              "Technodysis builds intelligent voice systems in Bangalore and deploys them globally across enterprises.",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(color: subtitleColor),
            ),
          ),

          /// GLOBE (responsive square; iframe fills cell)
          LayoutBuilder(
            builder: (context, constraints) {
              final side = _globeSideForLayoutWidth(constraints.maxWidth);
              return Center(
                child: SizedBox(
                  width: side,
                  height: side,
                  child: const GlobePage(),
                ),
              );
            },
          ),

          // AnimatedBuilder(
          //   animation: _globeController,
          //   builder: (_, __) {
          //     return CustomPaint(
          //       size: const Size(280, 280),
          //       painter: EarthGlobePainter(
          //         t: _globeController.value,
          //         isDark: isDark,
          //       ),
          //     );
          //   },
          // ),
          const SizedBox(height: 42),

          /// LANGUAGE PILLS
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: widget.langPills
                .map(
                  (pill) => LanguagePill(
                    label: pill.label,
                    isDark: isDark,
                    type: pill.type,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
