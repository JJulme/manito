import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/features/theme/theme_service.dart';

// ========== Service Provider ==========
final databaseService = Provider<DatabaseService>((_) => DatabaseService());

// ========== Notifier Provider ==========
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

// ========== Notifier ==========
class ThemeNotifier extends Notifier<ThemeMode> {
  late final DatabaseService _database;
  @override
  ThemeMode build() {
    _database = ref.read(databaseService);
    return _stringToThemeMode(_database.savedTheme);
  }

  // 현재 저장된 테마 정보
  // String get theme => _database.savedTheme;

  // 테마 변경
  Future<void> setTheme(ThemeMode mode) async {
    await _database.saveTheme(mode);
    state = mode;
  }

  // 테마 정보를 테마 모드로
  ThemeMode _stringToThemeMode(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
