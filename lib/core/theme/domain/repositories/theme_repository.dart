import 'package:flutter/material.dart';

abstract class ThemeRepository {
  Future<void> initTheme();
  String get savedTheme;
  Future<void> saveTheme(ThemeMode mode);
}
