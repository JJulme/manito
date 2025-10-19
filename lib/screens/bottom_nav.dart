import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/features/badge/badge_provider.dart';
import 'package:manito/screens/friends/friends_screen.dart';
import 'package:manito/screens/home_screen.dart';
import 'package:manito/screens/posts/post_screen.dart';
import 'package:manito/share/custom_badge.dart';
import 'package:manito/core/custom_icons.dart';

class BottomNav extends ConsumerStatefulWidget {
  const BottomNav({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BottomNavState();
}

class _BottomNavState extends ConsumerState<BottomNav>
    with WidgetsBindingObserver {
  /// 바텀 네비게이션 인덱스
  int _selectedIndex = 0;
  // 각 탭이 로드되었는지 추적하는 Set
  final Set<int> _loadedTabs = {0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(badgeProvider.notifier).fetchBadges();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // ✅ 앱이 포그라운드로 돌아왔을 때
        debugPrint('🔄 앱 재개 - 뱃지 동기화 시작');
        await ref.read(badgeProvider.notifier).syncBadgesAndDetectChange();
        break;

      case AppLifecycleState.paused:
        debugPrint('앱 일시중지');
        break;

      case AppLifecycleState.detached:
        debugPrint('앱 종료');
        break;

      case AppLifecycleState.hidden:
        debugPrint('앱 숨김');
        break;

      case AppLifecycleState.inactive:
        debugPrint('앱 비활성화');
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addObserver(this);
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (!_loadedTabs.contains(index)) {
        _loadedTabs.add(index);
      }
    });
  }

  // 선택된 화면 보여줌
  Widget _getScreen(int index) {
    if (!_loadedTabs.contains(index)) {
      return Center(child: CircularProgressIndicator());
    }
    switch (index) {
      case 0:
        return HomeScreen();
      case 1:
        return PostScreen();
      case 2:
        return FriendsScreen();
      default:
        return HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [_getScreen(0), _getScreen(1), _getScreen(2)],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: customBadgeIconWithLabel(
              ref.watch(badgeHomeCountProvider),
              child: Icon(Icons.home_filled, size: width * 0.065),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: customBadgeIconWithLabel(
              ref.watch(badgePostCountProvider),
              child: Icon(CustomIcons.flag_filled, size: width * 0.06),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: customBadgeIconWithLabel(
              ref.watch(specificBadgeProvider('friend_request')),
              child: Icon(CustomIcons.user, size: width * 0.055),
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}
