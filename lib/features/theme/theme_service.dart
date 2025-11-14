import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  // 테마 정보 저장 박스
  late final Box<String> themeBox;
  // 저장된 테마 정보 가져오는 객체
  String get savedTheme => themeBox.get('mode', defaultValue: 'system')!;
  // 테마 정보 초기화
  Future<void> initTheme() async {
    await Hive.openBox<String>('theme').then((value) => themeBox = value);
    if (!themeBox.containsKey('mode')) {
      await themeBox.put('mode', 'system');
    }
  }

  // 새로운 테마 저장
  Future<void> saveTheme(ThemeMode mode) async {
    await themeBox.put('mode', mode.name);
  }
}
