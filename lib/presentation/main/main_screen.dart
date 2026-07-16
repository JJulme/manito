import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/widget/common_badge.dart';
import 'package:manito/core/custom_icons.dart';
import 'package:manito/core/utils/logger.dart';
import 'package:manito/features_new/friends/presentation/screens/friends_screen.dart';
import 'package:manito/features_new/profile/presentation/screens/my_profile_screen.dart';
import 'package:manito/main.dart';
import 'package:manito/presentation/main/main_nav_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // ✅ 앱이 포그라운드로 돌아왔을 때
        Log.d('앱 재개 - 뱃지 리로드');
        break;

      case AppLifecycleState.paused:
        Log.d('앱 일시중지');
        break;

      case AppLifecycleState.detached:
        Log.d('앱 종료');
        break;

      case AppLifecycleState.hidden:
        Log.d('앱 숨김');
        break;

      case AppLifecycleState.inactive:
        Log.d('앱 비활성화');
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 화면 목록
    final List<Widget> screens = [MyProfileScreen(), Center(), FriendsScreen()];
    final selectedIndex = ref.watch(mainNavProvider);
    final navNotifier = ref.read(mainNavProvider.notifier);
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: ColorScheme.of(context).onSurface,
        onTap: (index) => navNotifier.setIndex(index),
        items: [
          BottomNavigationBarItem(
            label: '',
            icon: CommonBadge(
              badgeCount: 0,
              child: Icon(Icons.home_filled, size: width * 0.065),
            ),
          ),
          BottomNavigationBarItem(
            label: '',
            icon: CommonBadge(
              badgeCount: 0,
              child: Icon(CustomIcons.flag_filled, size: width * 0.06),
            ),
          ),
          BottomNavigationBarItem(
            label: '',
            icon: CommonBadge(
              badgeCount: 0,
              child: Icon(CustomIcons.user, size: width * 0.055),
            ),
          ),
        ],
      ),
    );
  }
}
