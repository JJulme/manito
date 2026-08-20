import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/theme/domain/repositories/repository_provider.dart';
import 'package:manito/core/theme/domain/repositories/theme_repository.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<ThemeMode> {
  late final ThemeRepository _repository;

  @override
  ThemeMode build() {
    _repository = ref.read(themeRepositoryProvider);
    return _stringToThemeMode(_repository.savedTheme);
  }

  Future<void> setTheme(ThemeMode mode) async {
    await _repository.saveTheme(mode);
    state = mode;
  }

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
