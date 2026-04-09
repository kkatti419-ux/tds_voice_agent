import 'package:flutter/material.dart';

import 'app_typography.dart';

/// App themes with **Poppins** as the font family for [ThemeData.textTheme].
abstract final class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5B6CFF),
      brightness: Brightness.dark,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
    );
    return base.copyWith(
      textTheme: AppTypography.materialTextTheme(base.textTheme),
      primaryTextTheme: AppTypography.materialTextTheme(base.primaryTextTheme),
    );
  }

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5B6CFF),
      brightness: Brightness.light,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
    );
    return base.copyWith(
      textTheme: AppTypography.materialTextTheme(base.textTheme),
      primaryTextTheme: AppTypography.materialTextTheme(base.primaryTextTheme),
    );
  }
}
