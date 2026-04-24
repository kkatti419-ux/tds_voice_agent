import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';
import 'package:tds_voice_agent/theme/app_typography.dart';
import 'package:tds_voice_agent/viewmodel/voice_viewmodel.dart';
import 'dart:ui_web' as ui;
// ignore: deprecated_member_use
import 'dart:html' as html;

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

    ui.platformViewRegistry.registerViewFactory('ai-face', (int viewId) {
      final iframe = html.IFrameElement()
        ..src = 'ai_robot.html'
        ..style.border = 'none'
        ..id = 'ai-face-iframe';
      return iframe;
    });
  }

  @override
  void dispose() {
    _orbController.dispose();
    super.dispose();
  }

  bool get isDark => widget.isDark;

<<<<<<< Updated upstream
  Color get bg => isDark ? AgniColors.black : AgniColors.neutralGrey;

  Color get border => isDark ? AgniColors.white12 : AgniColors.black12;

=======
>>>>>>> Stashed changes
  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceViewModel>(
      builder: (_, vm, _) {
        return Container(
          width: 320,
          height: 560,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF020617), const Color(0xFF0B1120)]
                  : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 80,
                spreadRadius: 10,
                color: Colors.black.withOpacity(.25),
                offset: const Offset(0, 40),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),

<<<<<<< Updated upstream
              /// Status
=======
              /// STATUS
>>>>>>> Stashed changes
              Text(
                vm.statusText,
                style: AppTypography.bodyMedium(
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.5),
                ).copyWith(fontSize: 13),
              ),

              const SizedBox(height: 20),

              /// ORB
              Expanded(child: _orb(vm)),

              /// PRICING
              _pricingCard(),

              const SizedBox(height: 20),

              /// MIC BUTTON
              _micButton(vm),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  /// 🔥 PREMIUM ORB
  Widget _orb(VoiceViewModel vm) {
    final speaking = vm.isAgentSpeaking;
    final listening = vm.isListening;

    String state = 'idle';
    if (speaking) {
      state = 'speaking';
    } else if (listening) {
      state = 'listening';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final iframe =
          html.document.getElementById('ai-face-iframe') as html.IFrameElement?;
      if (iframe != null) {
        iframe.src = 'ai_robot.html?state=$state';
      }
    });

    return AnimatedBuilder(
      animation: _orbController,
      builder: (_, _) {
        final pulse = math.sin(_orbController.value * math.pi);

        return Stack(
          alignment: Alignment.center,
          children: [
            /// background glow
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.blue.withOpacity(0.25), Colors.transparent],
                ),
              ),
            ),

            /// outer ring
            Container(
              width: 240 + pulse * 20,
              height: 240 + pulse * 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1.2,
                ),
              ),
            ),

            /// inner glow
            Container(
              width: 180 + pulse * 10,
              height: 180 + pulse * 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),

            /// AI FACE
            SizedBox(
              width: 200,
              height: 200,
              child: ClipOval(child: HtmlElementView(viewType: 'ai-face')),
            ),
          ],
        );
      },
    );
  }

  /// 💎 GLASS PRICING
  Widget _pricingCard() {
    final cardColor = isDark ? Colors.white : Colors.black;
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cardColor.withOpacity(0.05),
        border: Border.all(color: cardColor.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(
            "Pricing",
            style: AppTypography.bodyMedium(color: textColor.withOpacity(0.6)),
          ),
          const SizedBox(height: 4),
          Text(
            "₹2 / min",
            style: AppTypography.displaySmall(
              color: textColor,
            ).copyWith(fontSize: 22),
          ),
          Text(
            "AI Voice + Automation",
            style: AppTypography.bodyMedium(color: textColor.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  /// 🎤 PREMIUM BUTTON
  Widget _micButton(VoiceViewModel vm) {
    final muted = vm.micMutedByUser || !vm.isListening;

    return GestureDetector(
      onTap: vm.toggleListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: muted
                ? isDark
                      ? [Colors.grey.shade800, Colors.grey.shade900]
                      : [Colors.grey.shade300, Colors.grey.shade400]
                : [Colors.blue, Colors.purple],
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 30,
              color: muted ? Colors.transparent : Colors.blue.withOpacity(0.4),
            ),
          ],
        ),
        child: Text(
          muted ? "Tap to speak" : "Mute mic",
          style: TextStyle(
            color: isDark || !muted ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
