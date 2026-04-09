import 'package:flutter/material.dart';

class AgniColors {
  // Shared gradient colors
  static const Color oceanBright = Color(0xFF4EB3D3);
  static const Color forestBright = Color(0xFF74C69D);
  static const Color forestLight = Color(0xFF52B788);
  static const Color forestMid = Color(0xFF2D6A4F);
  static const Color oceanMid = Color(0xFF1A4A6B);
  static const Color oceanLight = Color(0xFF2D7DA8);

  static const Gradient grad = LinearGradient(
    begin: Alignment(-1, -1),
    end: Alignment(1, 1),
    colors: [Color(0xFF1A4A6B), Color(0xFF2D7DA8), Color(0xFF52B788)],
  );

  static const Gradient gradText = LinearGradient(
    colors: [Color(0xFF4EB3D3), Color(0xFF74C69D)],
  );

  static const Gradient gradTextLight = LinearGradient(
    colors: [Color(0xFF1A6A9A), Color(0xFF2D9A6F)],
  );

  static const Gradient gradOcean = LinearGradient(
    begin: Alignment(-1, -1),
    end: Alignment(1, 1),
    colors: [Color(0xFF1A4A6B), Color(0xFF2D7DA8), Color(0xFF4EB3D3)],
  );

  static const Gradient gradLand = LinearGradient(
    begin: Alignment(-1, -1),
    end: Alignment(1, 1),
    colors: [Color(0xFF2D6A4F), Color(0xFF52B788), Color(0xFF74C69D)],
  );

  // Dark mode
  static const Color darkBg = Color(0xFF030D1A);
  static const Color darkSurface = Color(0xFF08182C);
  static const Color darkText = Color(0xFFE8F4F8);
  static const Color darkText2 = Color(0xFFA8C8D8);
  static const Color darkText3 = Color(0xFF5A8098);
  static const Color darkBorder = Color(0xFF4EB3D3);
  static const Color darkOceanDeep = Color(0xFF071828);

  // Light mode
  static const Color lightBg = Color(0xFFEEF6F9);
  static const Color lightText = Color(0xFF0D1F2D);
  static const Color lightText2 = Color(0xFF2A4A5E);
  static const Color lightText3 = Color(0xFF5A7A8E);
  static const Color lightOceanDeep = Color(0xFF0A2342);

  // ─── Neutrals (use instead of Material [Colors.white] / [Colors.black]) ───

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  /// Opacity presets aligned with Material `Colors.whiteXX`.
  static const Color white12 = Color(0x1FFFFFFF);
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color white60 = Color(0x99FFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);

  /// Opacity presets aligned with Material `Colors.blackXX`.
  static const Color black12 = Color(0x1F000000);
  static const Color black26 = Color(0x42000000);
  static const Color black38 = Color(0x61000000);
  static const Color black45 = Color(0x73000000);
  static const Color black54 = Color(0x8A000000);
  static const Color black87 = Color(0xDD000000);

  /// Generic border / inactive grey (replaces [Colors.grey] in most cases).
  static const Color neutralGrey = Color(0xFF9E9E9E);

  /// Mic / activity (replaces [Colors.lime] / [Colors.limeAccent]).
  static const Color signalLime = Color(0xFFCDDC39);
  static const Color signalLimeAccent = Color(0xFFEEFF41);
}
