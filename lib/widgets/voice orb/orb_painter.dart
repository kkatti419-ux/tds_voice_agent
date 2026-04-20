import 'dart:math' as math;

import 'package:flutter/material.dart';

class OrbPainter extends CustomPainter {
  final double t;
  final bool speaking;
  final bool listening;

  OrbPainter({
    required this.t,
    required this.speaking,
    required this.listening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const R = 110.0;

    final center = Offset(cx, cy);

    /// 🎯 MODE
    double speed = 0.2;
    double waveAmp = 4;
    double opacity = 0.3;

    if (speaking) {
      speed = 2.5;
      waveAmp = 35;
      opacity = 1;
    } else if (listening) {
      speed = 1.2;
      waveAmp = 18;
      opacity = 0.8;
    }

    /// 🌊 OUTER GLOW
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [Colors.blue.withOpacity(opacity * 0.3), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: R + 40));

    canvas.drawCircle(center, R + 40, glow);

    /// 🌊 FLUID RING
    final path = Path();
    const points = 120;

    for (int i = 0; i <= points; i++) {
      final angle = (i / points) * 2 * math.pi;

      final wave =
          math.sin(angle * 4 + t * speed) * waveAmp +
          math.sin(angle * 6 - t * speed) * waveAmp * 0.5;

      final r = R + 15 + wave * 0.3;

      final x = cx + math.cos(angle) * r;
      final y = cy + math.sin(angle) * r;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();

    final ringPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.blue.withOpacity(opacity),
          Colors.blueAccent.withOpacity(opacity * 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: R + 40));

    canvas.drawPath(path, ringPaint);

    /// 🧊 INNER SPHERE
    final inner = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF0d2a45), Color(0xFF061828), Color(0xFF020c18)],
      ).createShader(Rect.fromCircle(center: center, radius: R));

    canvas.drawCircle(center, R, inner);

    /// 🌊 WATER
    final water = Path();
    // final baseY = cy + R * 0.1;
    final baseY = cy + R + 30; // pushes water below the circle

    water.moveTo(cx - R, baseY);
    // water.lineTo(cx + R, baseY + 60);
    // water.lineTo(cx - R, baseY + 60);

    for (double x = cx - R; x <= cx + R; x += 2) {
      final nx = (x - cx) / R;

      final y =
          baseY +
          math.sin(nx * math.pi * 3 + t * 2) * waveAmp * 0.5 +
          math.sin(nx * math.pi * 5 - t * 2.5) * waveAmp * 0.3;

      water.lineTo(x, y);
    }

    water.lineTo(cx + R, cy + R);
    water.lineTo(cx - R, cy + R);
    water.close();

    final waterPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.blue.withOpacity(0.6),
          Colors.blue.shade900.withOpacity(0.5),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: R));

    canvas.drawPath(water, waterPaint);

    /// 🧠 THINKING DOTS
    if (listening && !speaking) {
      for (int i = -1; i <= 1; i++) {
        final pulse = 0.5 + 0.5 * math.sin(t * 3 + i);
        final r = 4 + pulse * 3;

        canvas.drawCircle(
          Offset(cx + i * 18, cy),
          r,
          Paint()..color = Colors.lightBlueAccent,
        );
      }
    }

    /// 🎤 SPEAKING BARS
    if (speaking) {
      for (int i = 0; i < 7; i++) {
        final h = 10 + math.sin(t * 5 + i) * 25;

        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx - 42 + i * 14, cy),
            width: 6,
            height: h.abs(),
          ),
          const Radius.circular(4),
        );

        canvas.drawRRect(rect, Paint()..color = Colors.lightBlueAccent);
      }
    }

    /// OUTLINE
    final outline = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, R, outline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
