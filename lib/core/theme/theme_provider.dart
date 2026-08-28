import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _prefKey = 'app_theme_mode';

  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_prefKey);
      if (savedTheme == 'light') {
        state = ThemeMode.light;
      } else if (savedTheme == 'dark') {
        state = ThemeMode.dark;
      } else if (savedTheme == 'system') {
        state = ThemeMode.system;
      }
    } catch (_) {}
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
              ? 'dark'
              : 'system';
      await prefs.setString(_prefKey, modeStr);
    } catch (_) {}
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

