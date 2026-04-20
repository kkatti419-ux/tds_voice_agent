import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tds_voice_agent/widgets/voice%20orb/orb_painter.dart';

class VoiceOrb extends StatefulWidget {
  final bool speaking;
  final bool listening;

  const VoiceOrb({super.key, required this.speaking, required this.listening});

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          size: const Size(320, 320),
          painter: OrbPainter(
            t: _controller.value * 2 * math.pi,
            speaking: widget.speaking,
            listening: widget.listening,
          ),
        );
      },
    );
  }
}
