// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:tds_voice_agent/theme/app_typography.dart';
// import 'package:tds_voice_agent/viewmodel/voice_viewmodel.dart';

// class VoicePhoneWidget extends StatefulWidget {
//   final bool isDark;

//   const VoicePhoneWidget({super.key, required this.isDark});

//   @override
//   State<VoicePhoneWidget> createState() => _VoicePhoneWidgetState();
// }

// class _VoicePhoneWidgetState extends State<VoicePhoneWidget>
//     with TickerProviderStateMixin {
//   late AnimationController _orbController;

//   @override
//   void initState() {
//     super.initState();

//     _orbController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1600),
//     )..repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _orbController.dispose();
//     super.dispose();
//   }

//   Color get bg =>
//       widget.isDark ? const Color(0xFF08162A) : Colors.white;

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<VoiceViewModel>(
//       builder: (_, vm, __) {
//         return Container(
//           width: 320,
//           height: 560,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(36),
//             gradient: widget.isDark
//                 ? const LinearGradient(
//                     colors: [
//                       Color(0xFF071326),
//                       Color(0xFF0C1E3B),
//                     ],
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                   )
//                 : null,
//             color: widget.isDark ? const Color(0xFF08162A) : const Color(0xFFEEF6F9) ,
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(.25),
//                 blurRadius: 40,
//                 offset: const Offset(0, 25),
//               )
//             ],
//           ),
//           child: Column(
//             children: [
//               const SizedBox(height: 18),
//               /// Status text
//               Text(
//                 vm.statusText,
//                 style: 
//                 AppTypography.bodyMedium(color: widget.isDark ? Colors.white60 : Colors.black54).copyWith(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w500,
//                   color: widget.isDark
//                       ? Colors.white60
//                       : Colors.black54,
//                 ),
//               ),

//               const SizedBox(height: 30),
//               /// Animated Orb
//               Expanded(
//                 child: Center(child: _orb(vm)),
//               ),

//               _pricingCard(),

//               const SizedBox(height: 22),

//               _micButton(vm),

//               const SizedBox(height: 18),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   /// 🔥 Premium breathing orb with glow ring
//   Widget _orb(VoiceViewModel vm) {
//     final speaking = vm.isAgentSpeaking;
//     final listening = vm.isListening;

//     return AnimatedBuilder(
//       animation: _orbController,
//       builder: (_, __) {
//         final pulse =
//             math.sin(_orbController.value * math.pi);

//         double scale = 1;

//         if (speaking) {
//           scale = 1.1 + (.15 * pulse);
//         } else if (listening) {
//           scale = .9 + (.12 * pulse);
//         }

//         return Stack(
//           alignment: Alignment.center,
//           children: [
//             /// outer glow ring
//             Container(
//               width: 230 + (pulse * 20),
//               height: 230 + (pulse * 20),
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 gradient: RadialGradient(
//                   colors: [
//                     const Color(0xFF5B6CFF)
//                         .withOpacity(.25),
//                     Colors.transparent,
//                   ],
//                 ),
//               ),
//             ),

//             /// center orb
//             Transform.scale(
//               scale: scale,
//               child: Image.asset(
//                 "assets/images/little_sun.png",
//                 width: 200,
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   /// 💰 Premium pricing card
//   Widget _pricingCard() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 28),
//       padding: const EdgeInsets.symmetric(
//         vertical: 12,
//         horizontal: 18,
//       ),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(18),
//         gradient: LinearGradient(
//           colors: [
//             Colors.green.withOpacity(.18),
//             Colors.green.withOpacity(.05),
//           ],
//         ),
//         border: Border.all(
//           color: Colors.green.withOpacity(.5),
//         ),
//       ),
//       child: Column(
//         children: [
//           Text(
//             "Pricing",
//             style: AppTypography.bodyMedium(
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             "₹2 / min",
//             style: AppTypography.displaySmall(
//               color: Colors.white,
//             ).copyWith(fontSize: 22),
//           ),
//           Text(
//             "AI Voice + Automation",
//             style: AppTypography.bodyMedium(
//               color: Colors.white70,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// 🎤 Gradient mic button
//   Widget _micButton(VoiceViewModel vm) {
//     final muted = vm.micMutedByUser || !vm.isListening;

//     return GestureDetector(
//       onTap: vm.toggleListening,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 250),
//         padding: const EdgeInsets.symmetric(
//           horizontal: 28,
//           vertical: 14,
//         ),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           gradient: const LinearGradient(
//             colors: [
//               Color(0xFF5B6CFF),
//               Color(0xFF8E44AD),
//             ],
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: const Color(0xFF5B6CFF)
//                   .withOpacity(.4),
//               blurRadius: 20,
//               offset: const Offset(0, 8),
//             )
//           ],
//         ),
//         child: Text(
//           muted ? "Tap to speak" : "Mute mic",
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 15,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';
import 'package:tds_voice_agent/theme/app_typography.dart';
import 'package:tds_voice_agent/viewmodel/voice_viewmodel.dart';

class VoicePhoneWidget extends StatefulWidget {
  final bool isDark;

  const VoicePhoneWidget({super.key, required this.isDark});

  @override
  State<VoicePhoneWidget> createState() => _VoicePhoneWidgetState();
}

class _VoicePhoneWidgetState extends State<VoicePhoneWidget>
    with TickerProviderStateMixin {
  late AnimationController _orbController;

  @override
  void initState() {
    super.initState();

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbController.dispose();
    super.dispose();
  }

  bool get isDark => widget.isDark;

  Color get bg => isDark ? AgniColors.black : AgniColors.neutralGrey;

  Color get border =>
      isDark ? AgniColors.white12 : AgniColors.black12;

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceViewModel>(
      builder: (_, vm, __) {
        return Container(
          width: 320,
          height: 560,
          decoration: BoxDecoration(
            gradient: 
            isDark ? 
            AgniColors.grad.withOpacity(0.3):AgniColors.gradTextLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                blurRadius: 60,
                offset: const Offset(0, 30),
                color: AgniColors.black.withOpacity(.18),
              )
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 22),

              /// Status
              Text(
                vm.statusText,
                style: AppTypography.bodyMedium(
                  color: isDark
                      ? AgniColors.white60
                      : AgniColors.black54,
                ),
              ),

              const SizedBox(height: 30),

              Expanded(child: _orb(vm)),

              _pricingCard(),

              const SizedBox(height: 26),

              _micButton(vm),

              const SizedBox(height: 22),
            ],
          ),
        );
      },
    );
  }

  /// Orb animation (monochrome halo breathing)
  Widget _orb(VoiceViewModel vm) {
    final speaking = vm.isAgentSpeaking;
    final listening = vm.isListening;

    return AnimatedBuilder(
      animation: _orbController,
      builder: (_, __) {
        final pulse =
            math.sin(_orbController.value * math.pi);

        double scale = 1;

        if (speaking) {
          scale = 1.08 + (.12 * pulse);
        } else if (listening) {
          scale = .92 + (.08 * pulse);
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            /// outer halo ring
            Container(
              width: 240 + pulse * 16,
              height: 240 + pulse * 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AgniColors.white12
                      : AgniColors.black12,
                  width: 1.4,
                ),
              ),
            ),

            /// center orb
            Transform.scale(
              scale: scale,
              child: Image.asset(
                "assets/images/little_sun.png",
                width: 190,
                // color: isDark ? Colors.white : Colors.black,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Pricing badge (clean minimal chip style)
  Widget _pricingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        color: AgniColors.forestLight
        // isDark ? const Color(0xFF08162A) : const Color(0xFFEEF6F9),
      ),
      child: Column(
        children: [
          Text(
            "Pricing",
            style: AppTypography.bodyMedium(
              color: isDark
                  ? AgniColors.white70
                  : AgniColors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "₹2 / min",
            style: AppTypography.displaySmall(
              color: isDark
                  ? AgniColors.white
                  : AgniColors.black,
            ).copyWith(fontSize: 22),
          ),
          Text(
            "AI Voice + Automation",
            style: AppTypography.bodyMedium(
              color: isDark
                  ? AgniColors.white60
                  : AgniColors.black45,
            ),
          ),
        ],
      ),
    );
  }

  /// Mic button (Apple-style minimal CTA)
  Widget _micButton(VoiceViewModel vm) {
    final muted = vm.micMutedByUser || !vm.isListening;

    return GestureDetector(
      onTap: vm.toggleListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(
          horizontal: 34,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark
              ? AgniColors.white
              : AgniColors.black,
        ),
        child: Text(
          muted ? "Tap to speak" : "Mute mic",
          style: TextStyle(
            color: isDark
                ? AgniColors.black
                : AgniColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}