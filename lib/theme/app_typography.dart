import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central text styles for the app — **all use the Poppins family**.
///
/// Usage:
/// ```dart
/// Text('Hello', style: AppTypography.titleLarge(color: Colors.white));
/// Text('Body', style: Theme.of(context).textTheme.bodyMedium);
/// ```
///
/// With [AppTheme], [ThemeData.textTheme] is already Poppins via
/// [materialTextTheme].
abstract final class AppTypography {
  AppTypography._();

  // ─── Core: shared builder ─────────────────────────────────────────────────

  static TextStyle poppins({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
    double? letterSpacing,
    Color? color,
    TextDecoration? decoration,
    Paint? foreground,
    Paint? background,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      decoration: decoration,
      foreground: foreground,
      background: background,
    );
  }

  /// Applies **Poppins** to every role in a Material [TextTheme] (from [ThemeData]).
  static TextTheme materialTextTheme(TextTheme base) =>
      GoogleFonts.poppinsTextTheme(base);

  // ─── Material 3 scale (sizes align with M3 defaults) ─────────────────────

  static TextStyle displayLarge({Color? color}) => poppins(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        height: 1.12,
        letterSpacing: -0.25,
        color: color,
      );

  static TextStyle displayMedium({Color? color}) => poppins(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        height: 1.16,
        color: color,
      );

  static TextStyle displaySmall({Color? color}) => poppins(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        height: 1.22,
        color: color,
      );

  static TextStyle headlineLarge({Color? color}) => poppins(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        height: 1.25,
        color: color,
      );

  static TextStyle headlineMedium({Color? color}) => poppins(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        height: 1.29,
        color: color,
      );

  static TextStyle headlineSmall({Color? color}) => poppins(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 1.33,
        color: color,
      );

  static TextStyle titleLarge({Color? color}) => poppins(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.27,
        color: color,
      );

  static TextStyle titleMedium({Color? color}) => poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.50,
        letterSpacing: 0.15,
        color: color,
      );

  static TextStyle titleSmall({Color? color}) => poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle bodyLarge({Color? color}) => poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.50,
        letterSpacing: 0.5,
        color: color,
      );

  static TextStyle bodyMedium({Color? color}) => poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        letterSpacing: 0.25,
        color: color,
      );

  static TextStyle bodySmall({Color? color}) => poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        letterSpacing: 0.4,
        color: color,
      );

  static TextStyle labelLarge({Color? color}) => poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle labelMedium({Color? color}) => poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.33,
        letterSpacing: 0.5,
        color: color,
      );

  static TextStyle labelSmall({Color? color}) => poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0.5,
        color: color,
      );

  // ─── Semantic aliases (same Poppins; common app roles) ───────────────────

  /// Primary marketing / hero headline (large, tight).
  static TextStyle heroDisplay({Color? color}) => poppins(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -1.0,
        color: color,
      );

  static TextStyle heroSubtitle({Color? color}) => poppins(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.75,
        color: color,
      );

  /// Top navigation links.
  static TextStyle navItem({Color? color}) => poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: color,
      );

  /// Marketing wordmark / logo text (replaces separate display fonts if you want pure Poppins).
  static TextStyle brandWordmark({Color? color}) => poppins(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.2,
        color: color,
      );

  /// Compact CTA pill (nav bar, chips).
  static TextStyle ctaCompact({Color? color}) => poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: color,
      );

  /// Primary filled button label.
  static TextStyle buttonPrimary({Color? color}) => poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.2,
        color: color,
      );

  /// Outlined / text button label.
  static TextStyle buttonSecondary({Color? color}) => poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: color,
      );

  static TextStyle cardTitle({Color? color}) => poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: color,
      );

  static TextStyle cardBody({Color? color}) => poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle caption({Color? color}) => poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color,
      );

  static TextStyle overline({Color? color}) => poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: 1.2,
        color: color,
      );

  /// Badge / pill text.
  static TextStyle badge({Color? color}) => poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: color,
      );

  /// App bar title.
  static TextStyle appBarTitle({Color? color}) => poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: color,
      );

  /// Form field labels.
  static TextStyle inputLabel({Color? color}) => poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: color,
      );

  static TextStyle inputText({Color? color}) => poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle inputHint({Color? color}) => poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  /// Chat / message bubble.
  static TextStyle messageBody({Color? color}) => poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color,
      );

  static TextStyle statusLine({Color? color}) => poppins(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: color,
      );
}
