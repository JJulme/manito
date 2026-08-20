import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:manito/core/theme/domain/repositories/theme_repository.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  late final Box<String> _themeBox;

  @override
  String get savedTheme => _themeBox.get('mode', defaultValue: 'system')!;

  @override
  Future<void> initTheme() async {
    _themeBox = await Hive.openBox<String>('theme');
    if (!_themeBox.containsKey('mode')) {
      await _themeBox.put('mode', 'system');
    }
  }

  @override
  Future<void> saveTheme(ThemeMode mode) async {
    await _themeBox.put('mode', mode.name);
  }
}
