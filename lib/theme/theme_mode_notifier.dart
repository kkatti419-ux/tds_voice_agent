import 'package:flutter/material.dart';

/// Drives [MaterialApp.themeMode]; toggled from the landing navbar/drawer.
class ThemeModeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get themeMode => _mode;

  void toggle() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
