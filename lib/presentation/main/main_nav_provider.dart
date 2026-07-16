// lib/presentation/main/providers/main_nav_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainNavNotifier extends Notifier<int> {
  @override
  int build() => 0; // 초기값 (홈 탭)

  void setIndex(int index) {
    state = index;
  }
}

final mainNavProvider = NotifierProvider<MainNavNotifier, int>(() {
  return MainNavNotifier();
});
