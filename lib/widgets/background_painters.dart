import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';

class BackgroundPainter extends CustomPainter {
  final bool isDark;
  final double t;

  BackgroundPainter({required this.isDark, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    if (isDark) {
      _paintDark(canvas, size);
    } else {
      _paintLight(canvas, size);
    }
  }

  void _paintDark(Canvas canvas, Size size) {
    final baseRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(baseRect, Paint()..color = const Color(0xFF030D1A));

    final blobs = [
      (size.width * 0.0, size.height * 0.0, 700.0, const Color(0xFF0E3A60), 0.55),
      (size.width - 150, size.height - 120, 600.0, const Color(0xFF1A4030), 0.45),
      (size.width * 0.38, size.height * 0.38, 500.0, const Color(0xFF0A2D4A), 0.35),
      (size.width * 0.78, size.height * 0.15, 350.0, const Color(0xFF2D6A4F), 0.25),
      (size.width * 0.05, size.height * 0.75, 280.0, const Color(0xFF4EB3D3), 0.10),
    ];

    for (final b in blobs) {
      final paint = Paint()
        ..color = b.$4.withOpacity(b.$5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
      canvas.drawCircle(Offset(b.$1, b.$2), b.$3 / 2, paint);
    }
  }

  void _paintLight(Canvas canvas, Size size) {
    final baseRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(-0.5, -1),
        end: Alignment(0.5, 1),
        colors: [Color(0xFFDAEEF8), Color(0xFFE8F5F0), Color(0xFFD8EEE0)],
      ).createShader(baseRect);
    canvas.drawRect(baseRect, bgPaint);

    final blobs = [
      (size.width * 0.15, size.height * 0.20, 650.0, const Color(0xFF7AB8D8), 0.18),
      (size.width - 120, size.height - 100, 550.0, const Color(0xFF52B788), 0.16),
      (size.width * 0.40, size.height * 0.45, 420.0, const Color(0xFF2D7DA8), 0.12),
      (size.width * 0.90, size.height * 0.20, 300.0, const Color(0xFF74C69D), 0.14),
    ];

    for (final b in blobs) {
      final paint = Paint()
        ..color = b.$4.withOpacity(b.$5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
      canvas.drawCircle(Offset(b.$1, b.$2), b.$3 / 2, paint);
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter old) => old.isDark != isDark;
}

class GlobeBgPainter extends CustomPainter {
  final bool isDark;
  final double t;

  GlobeBgPainter({required this.isDark, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final pulse = 1.0 + math.sin(t * math.pi) * 0.02;
    final r = (size.width / 2) * pulse;

    if (!isDark) {
      // Light mode: colored radial inside circle
      final p = Paint()..color = AgniColors.oceanBright.withOpacity(0.15);
      p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
      canvas.drawCircle(center, r, p);
    }

    // Rings
    final ringPaint = Paint()
      ..color = (isDark ? AgniColors.oceanBright : AgniColors.oceanMid)
          .withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, r, ringPaint);

    final ringPaint2 = Paint()
      ..color = (isDark ? AgniColors.forestLight : AgniColors.forestMid)
          .withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, r - 50, ringPaint2);

    final ringPaint3 = Paint()
      ..color = (isDark ? AgniColors.oceanBright : AgniColors.oceanMid)
          .withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, r - 110, ringPaint3);
  }

  @override
  bool shouldRepaint(GlobeBgPainter old) => old.t != t || old.isDark != isDark;
}
