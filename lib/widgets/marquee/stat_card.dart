// import 'package:flutter/material.dart';
// import 'package:tds_voice_agent/theme/app_typography.dart';

// class StatCard extends StatelessWidget {
//   final String value;
//   final String description;
//   final bool isDark;

//   const StatCard({
//     super.key,
//     required this.value,
//     required this.description,
//     required this.isDark,
//   });

//   Color get text3Color => isDark ? Colors.white60 : Colors.black54;

//   final LinearGradient gradText = const LinearGradient(
//     colors: [Color(0xFF5B6CFF), Color(0xFF8E44AD)],
//   );

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
//         borderRadius: BorderRadius.circular(32),
//         border: Border.all(color: Colors.grey.withOpacity(0.2)),
//       ),
//       child: Stack(
//         children: [
//           // 🔥 Top gradient line
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             child: Container(
//               height: 2,
//               decoration: const BoxDecoration(

//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(32),
//                   topRight: Radius.circular(32),
//                 ),
//               ),
//             ),
//           ),

//           Padding(
//             padding: const EdgeInsets.all(10),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // 🎨 Gradient number
//                 ShaderMask(
//                   shaderCallback: (bounds) => gradText.createShader(bounds),
//                   child: Text(
//                     value,
//                     style:
//                     AppTypography.displaySmall(color: Colors.white),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   description,
//                   style:
//                   AppTypography.bodyMedium(color: text3Color),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';
import 'package:tds_voice_agent/theme/app_typography.dart';

/// Fixed height so stat rows stay aligned when titles wrap (e.g. "650+ automations").
/// Tall enough for two-line value + three-line description inside padded container.
const double kStatCardHeight = 200;

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

  Color get textSecondary => isDark ? AgniColors.white60 : AgniColors.black54;

  Color get cardColor =>
      isDark ? AgniColors.darkBg : AgniColors.lightBg.withOpacity(0.8);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kStatCardHeight,
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AgniColors.neutralGrey.withOpacity(0.15)),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: AgniColors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF5B6CFF),
                    Color(0xFF7B61FF),
                    Color(0xFF8E44AD),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.displaySmall(color: AgniColors.white)
                      .copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium(
                  color: textSecondary,
                ).copyWith(fontSize: 20, letterSpacing: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
