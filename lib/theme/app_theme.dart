import 'package:flutter/material.dart';

import '../core/agni_colors.dart';
import 'app_typography.dart';

/// Brand-aligned Material 3 themes (ocean / forest) with Poppins.
abstract final class AppTheme {
  AppTheme._();

  static ColorScheme _darkColorScheme() {
    const onDark = Color(0xFF041018);
    return ColorScheme(
      brightness: Brightness.dark,
      primary: AgniColors.oceanBright,
      onPrimary: onDark,
      primaryContainer: const Color(0xFF0E3A52),
      onPrimaryContainer: AgniColors.darkText,
      secondary: AgniColors.forestLight,
      onSecondary: onDark,
      secondaryContainer: const Color(0xFF1A4D3A),
      onSecondaryContainer: const Color(0xFFC8F0DD),
      tertiary: AgniColors.oceanLight,
      onTertiary: onDark,
      tertiaryContainer: const Color(0xFF154A66),
      onTertiaryContainer: AgniColors.darkText2,
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: AgniColors.darkSurface,
      onSurface: AgniColors.darkText,
      surfaceContainerHighest: const Color(0xFF122536),
      surfaceContainerHigh: const Color(0xFF0F2030),
      surfaceContainer: const Color(0xFF0C1A28),
      surfaceContainerLow: const Color(0xFF081420),
      surfaceContainerLowest: AgniColors.darkBg,
      onSurfaceVariant: AgniColors.darkText2,
      outline: const Color(0xFF5A8098),
      outlineVariant: const Color(0xFF3A5060),
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: AgniColors.lightBg,
      onInverseSurface: AgniColors.lightText,
      inversePrimary: AgniColors.oceanMid,
      surfaceTint: AgniColors.oceanBright.withValues(alpha: 0.35),
    );
  }

  static ColorScheme _lightColorScheme() {
    const onLight = Color(0xFFFFFFFF);
    return ColorScheme(
      brightness: Brightness.light,
      primary: AgniColors.oceanMid,
      onPrimary: onLight,
      primaryContainer: const Color(0xFFC8E8F4),
      onPrimaryContainer: AgniColors.lightOceanDeep,
      secondary: AgniColors.forestMid,
      onSecondary: onLight,
      secondaryContainer: const Color(0xFFB8E8D0),
      onSecondaryContainer: const Color(0xFF0D3D2A),
      tertiary: AgniColors.oceanLight,
      onTertiary: onLight,
      tertiaryContainer: const Color(0xFFB8DCF0),
      onTertiaryContainer: const Color(0xFF0A2840),
      error: const Color(0xFFBA1A1A),
      onError: onLight,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: AgniColors.lightBg,
      onSurface: AgniColors.lightText,
      surfaceContainerHighest: const Color(0xFFE2EEF3),
      surfaceContainerHigh: const Color(0xFFE8F1F5),
      surfaceContainer: const Color(0xFFEEF6F9),
      surfaceContainerLow: const Color(0xFFF3F8FA),
      surfaceContainerLowest: Colors.white,
      onSurfaceVariant: AgniColors.lightText2,
      outline: const Color(0xFF6A8A9E),
      outlineVariant: const Color(0xFFC0D4E0),
      shadow: Colors.black26,
      scrim: Colors.black38,
      inverseSurface: AgniColors.lightOceanDeep,
      onInverseSurface: AgniColors.lightBg,
      inversePrimary: AgniColors.oceanBright,
      surfaceTint: AgniColors.oceanMid.withValues(alpha: 0.12),
    );
  }

  static ThemeData _applyComponents(ThemeData base, ColorScheme cs) {
    final isLight = cs.brightness == Brightness.light;
    final radius = BorderRadius.circular(16);
    final smallRadius = BorderRadius.circular(12);

    return base.copyWith(
      scaffoldBackgroundColor: cs.surface,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: isLight ? 1 : 0.5,
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: cs.surfaceTint,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: cs.onSurface, size: 22),
        actionsIconTheme: IconThemeData(color: cs.onSurface, size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: isLight ? 1 : 0,
        shadowColor: Colors.black.withValues(alpha: isLight ? 0.08 : 0.35),
        shape: RoundedRectangleBorder(borderRadius: radius),
        color: cs.surfaceContainerHighest,
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        elevation: isLight ? 3 : 2,
        shape: RoundedRectangleBorder(borderRadius: radius),
        titleTextStyle: base.textTheme.titleLarge?.copyWith(color: cs.onSurface),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius.topLeft.x)),
        ),
        showDragHandle: true,
      ),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: cs.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: smallRadius),
        elevation: 2,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: cs.inverseSurface,
          borderRadius: smallRadius,
        ),
        textStyle: base.textTheme.bodySmall?.copyWith(
          color: cs.onInverseSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: cs.onSurfaceVariant,
        textColor: cs.onSurface,
        selectedColor: cs.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: cs.onPrimary,
          backgroundColor: cs.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          elevation: isLight ? 0 : 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: cs.onPrimary,
          backgroundColor: cs.primary,
          elevation: isLight ? 1 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData dark() {
    final cs = _darkColorScheme();
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
    );
    final withFonts = base.copyWith(
      textTheme: AppTypography.materialTextTheme(base.textTheme),
      primaryTextTheme: AppTypography.materialTextTheme(base.primaryTextTheme),
    );
    return _applyComponents(withFonts, cs);
  }

  static ThemeData light() {
    final cs = _lightColorScheme();
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,
    );
    final withFonts = base.copyWith(
      textTheme: AppTypography.materialTextTheme(base.textTheme),
      primaryTextTheme: AppTypography.materialTextTheme(base.primaryTextTheme),
    );
    return _applyComponents(withFonts, cs);
  }
}
