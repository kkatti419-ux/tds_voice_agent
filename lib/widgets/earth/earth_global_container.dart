import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';

class EarthGlobePainter extends CustomPainter {
  final double t; // 0..1 from AnimationController (globeController, 8s reverse)
  final bool isDark;

  EarthGlobePainter({required this.t, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final globeRect = Rect.fromCircle(center: center, radius: r);

    // globeSpin: 20s ease-in-out infinite alternate — shifts continent positions slightly
    // We simulate by offsetting patch centers slightly over time
    final spinOffset = math.sin(t * math.pi) * 0.04; // ±4% drift

    // ── 1. Clip everything to the circle ──────────────────────────────────
    final clipPath = Path()..addOval(globeRect);
    canvas.save();
    canvas.clipPath(clipPath);

    // ── 2. Base layer: radial(50%50%, #1a4a6b → #0a2342) ─────────────────
    // This is the deepest ocean base
    final basePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: const [Color(0xFF1A4A6B), Color(0xFF0A2342)],
      ).createShader(globeRect);
    canvas.drawOval(globeRect, basePaint);

    // ── 3. Continent patch: radial(75% 25%, #7ab8d8 → transparent 35%) ───
    // Top-right blue water highlight
    _drawRadialPatch(
      canvas,
      center,
      r,
      cx: 0.75 + spinOffset,
      cy: 0.25,
      stop0: 0.0,
      stop1: 0.35,
      c0: const Color(0xFF7AB8D8),
      c1: AgniColors.transparent,
    );

    // ── 4. Continent patch: radial(20% 70%, #74c69d → transparent 35%) ───
    // Bottom-left forest green
    _drawRadialPatch(
      canvas,
      center,
      r,
      cx: 0.20 - spinOffset,
      cy: 0.70,
      stop0: 0.0,
      stop1: 0.35,
      c0: const Color(0xFF74C69D),
      c1: AgniColors.transparent,
    );

    // ── 5. Continent patch: radial(68% 58%, #52b788 → #2d6a4f 25%, transp 55%) ─
    // Center-right green landmass
    _drawRadialPatch(
      canvas,
      center,
      r,
      cx: 0.68 + spinOffset * 0.5,
      cy: 0.58,
      stop0: 0.0,
      midStop: 0.25,
      stop1: 0.55,
      c0: const Color(0xFF52B788),
      cMid: const Color(0xFF2D6A4F),
      c1: AgniColors.transparent,
    );

    // ── 6. Continent patch: radial(32% 38%, #4eb3d3 → #2d7da8 25%, transp 55%) ─
    // Top-left ocean blue (painted last = frontmost in CSS stacking = first in CSS list)
    _drawRadialPatch(
      canvas,
      center,
      r,
      cx: 0.32 - spinOffset * 0.5,
      cy: 0.38,
      stop0: 0.0,
      midStop: 0.25,
      stop1: 0.55,
      c0: const Color(0xFF4EB3D3),
      cMid: const Color(0xFF2D7DA8),
      c1: AgniColors.transparent,
    );

    // ── 7. ::before highlight: radial(28% 32%, rgba(255,255,255,.15) → transp 30%) ─
    _drawRadialPatch(
      canvas,
      center,
      r,
      cx: 0.28,
      cy: 0.32,
      stop0: 0.0,
      stop1: 0.30,
      c0: AgniColors.white.withOpacity(0.15),
      c1: AgniColors.transparent,
    );

    canvas.restore(); // end clip

    // ── 8. Inset shadows (simulated as overlays inside clip) ───────────────
    // inset -30px -20px 60px rgba(10,35,66,.40) → dark bottom-right
    // inset 20px 15px 40px rgba(255,255,255,.08) → light top-left
    canvas.save();
    canvas.clipPath(clipPath);

    // Dark side: bottom-right
    final darkInset = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, 0.75),
        radius: 0.9,
        colors: [
          AgniColors.lightOceanDeep.withOpacity(0.40),
          AgniColors.transparent,
        ],
      ).createShader(globeRect)
      ..blendMode = BlendMode.srcOver;
    canvas.drawOval(globeRect, darkInset);

    // Light side: top-left
    final lightInset = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.5, -0.55),
        radius: 0.7,
        colors: [
          AgniColors.white.withOpacity(0.08),
          AgniColors.transparent,
        ],
      ).createShader(globeRect);
    canvas.drawOval(globeRect, lightInset);

    canvas.restore();

    // ── 9. Outer glow & ring (box-shadow) ─────────────────────────────────
    // Dark mode pulses: globePulse 8s ease-in-out infinite
    final glowPulse = isDark
        ? 0.20 +
              math.sin(t * math.pi) *
                  0.15 // 0.20→0.35
        : 0.20;

    // box-shadow: 0 0 0 1px rgba(78,179,211,.25)  ← 1px ring
    final ringPaint = Paint()
      ..color = const Color(0xFF4EB3D3).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, r + 0.5, ringPaint);

    // box-shadow: 0 0 60px rgba(78,179,211,.20)  ← soft outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFF4EB3D3).withOpacity(glowPulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, r + 2, glowPaint);

    // box-shadow: 0 20px 80px rgba(10,35,66,.30)  ← drop shadow
    // Drawn as a downward-offset blurred circle
    final dropPaint = Paint()
      ..color = const Color(0xFF0A2342).withOpacity(0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(Offset(center.dx, center.dy + 20), r * 0.85, dropPaint);
  }

  /// Draw a radial gradient patch anchored at (cx*diameter, cy*diameter) relative to globe top-left.
  /// Supports 2-stop or 3-stop gradients matching CSS radial-gradient(circle at X% Y%, c0 s0, [cMid sMid,] c1 s1)
  void _drawRadialPatch(
    Canvas canvas,
    Offset center,
    double r, {
    required double cx,
    required double cy,
    required double stop0,
    required double stop1,
    required Color c0,
    required Color c1,
    double? midStop,
    Color? cMid,
  }) {
    // Center of this patch in canvas coordinates
    final patchCenter = Offset(
      center.dx + (cx - 0.5) * r * 2,
      center.dy + (cy - 0.5) * r * 2,
    );
    // Radius of patch = stop1 * globe diameter
    final patchRadius = stop1 * r * 2;
    final patchRect = Rect.fromCircle(center: patchCenter, radius: patchRadius);

    final List<Color> colors;
    final List<double> stops;

    if (midStop != null && cMid != null) {
      colors = [c0, cMid, c1];
      stops = [stop0, midStop / stop1, 1.0];
    } else {
      colors = [c0, c1];
      stops = [stop0, 1.0];
    }

    final paint = Paint()
      ..shader = RadialGradient(
        colors: colors,
        stops: stops,
      ).createShader(patchRect);

    canvas.drawCircle(patchCenter, patchRadius, paint);
  }

  @override
  bool shouldRepaint(EarthGlobePainter old) =>
      old.t != t || old.isDark != isDark;
}
