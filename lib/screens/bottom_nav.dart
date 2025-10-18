import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/arch_new/screens/home_screen.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/badge_controller.dart';
import 'package:manito/custom_icons.dart';
import 'package:manito/firebase_handler.dart';
import 'package:manito/screens/friend/friends_screen.dart';
import 'package:manito/screens/manito/manito_screen.dart';
import 'package:manito/screens/post/post_screen.dart';
import 'package:manito/widgets/common/custom_badge.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

// Key for SharedPreferences
const String kHasShownTutorial = 'has_shown_tutorial';

/// Bottom Nav Bar
class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> with WidgetsBindingObserver {
  /// 바텀 네비게이션 인덱스
  int _selectedIndex = 0;

  // 각 탭이 로드되었는지 추적하는 Set
  final Set<int> _loadedTabs = {0};

  // 컨트롤러, 수파베이스
  final BadgeController _badgeController = Get.find<BadgeController>();
  final supabase = Supabase.instance.client;

  // 튜토리얼 관련 변수
  final GlobalKey _friendIconKey = GlobalKey();
  final GlobalKey _postIconKey = GlobalKey();
  final GlobalKey _missionIconKey = GlobalKey();
  final GlobalKey _manitoIconKey = GlobalKey();
  late TutorialCoachMark tutorialCoachMark;
  late double width;

  @override
  void initState() {
    super.initState();
    width = Get.width;
    WidgetsBinding.instance.addObserver(this); // 등록
    _handleFCMToken();
  }

  // 튜토리얼 초기화를 위해 생성
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // _initTutorial();
    // if (mounted) {
    //   tutorialCoachMark.show(context: context);
    // }
    _checkAndShowTutorial();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 해제
    super.dispose();
  }

  // 앱 백그라운드일 이후 뱃지 데이터 가져오기
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    // 앱이 포커스를 받을 때
    if (state == AppLifecycleState.resumed) {
      await _badgeController.fetchExistingBadges();
    }
  }

  // 탭 눌렀을때 동작
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // 해당 탭이 처음 로드되는 경우 위젯 생성
      if (!_loadedTabs.contains(index)) {
        _loadedTabs.add(index);
      }
    });
    // 포스트 탭 클릭
    if (index == 1) {
      _badgeController.resetBadgeCount('mission_complete');
    }
    // 미션 탭 클릭
    else if (index == 2) {
      _badgeController.resetBadgeCount('mission_accept');
      _badgeController.resetBadgeCount('mission_guess');
    }
    // 마니또 탭 클릭
    else if (index == 3) {
      _badgeController.resetBadgeCount('mission_propose');
    }
  }

  // 선택된 화면 보여줌
  Widget _getScreen(int index) {
    if (!_loadedTabs.contains(index)) {
      return Center(child: CircularProgressIndicator());
    }
    switch (index) {
      case 0:
        return FriendsScreen();
      case 1:
        return PostScreen();
      case 2:
        // return MissionScreen();
        return HomeScreen();
      case 3:
        return ManitoScreen();
      default:
        return FriendsScreen();
    }
  }

  /// 토큰 저장
  Future<void> _handleFCMToken() async {
    try {
      // FCM(푸시 알림) 권한 요청
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (!mounted) return;
        customSnackbar(
          title: context.tr("bottom_nav.fcm_snack_title"),
          message: context.tr("bottom_nav.fcm_snack_message"),
        );
      }

      // 토큰 설정
      await FirebaseMessaging.instance.getAPNSToken();
      final fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM Token: $fcmToken');

      // FCM 토큰이 null이 아닐 경우, 서버에 토큰 저장
      if (fcmToken != null) {
        await _setFCMToken(fcmToken);
      }

      // FCM 토큰이 갱신될 때의 리스너 설정
      FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
        // 갱신된 FCM 토큰을 서버에 저장
        await _setFCMToken(fcmToken);
      });

      /// 포그라운드 - 뱃지 / 앱내 알림 / 데이터 새로고침
      FirebaseMessaging.onMessage.listen(handleForegroundMessage);
    } catch (e) {
      debugPrint('_handleFCMToken Error: $e');
      if (!mounted) return;
      customSnackbar(
        title: context.tr("bottom_nav.token_error_snack_title"),
        message: context.tr("bottom_nav.token_error_snack_message"),
      );
    }
  }

  /// FCM 토큰을 Supabase의 프로필 테이블에 저장하는 메서드
  Future<void> _setFCMToken(String fcmToken) async {
    final userId = supabase.auth.currentUser!.id;
    // 사용자 ID와 FCM 토큰을 프로필 테이블에 upsert (업데이트 또는 삽입) 수행
    await supabase.from('profiles').upsert({
      'id': userId,
      'fcm_token': fcmToken,
    });
  }

  void _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasShown = prefs.getBool(kHasShownTutorial) ?? false;

    if (!hasShown) {
      _initTutorial();
      if (mounted) {
        tutorialCoachMark.show(context: context);
        await prefs.setBool(kHasShownTutorial, true);
      }
    }
  }

  // 튜토리얼 초기화
  void _initTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: [
        _createTarget(_friendIconKey, context.tr('bottom_nav.tutorial1')),
        _createTarget(_postIconKey, context.tr('bottom_nav.tutorial2')),
        _createTarget(_missionIconKey, context.tr('bottom_nav.tutorial3')),
        _createTarget(_manitoIconKey, context.tr('bottom_nav.tutorial4')),
      ],
      colorShadow: Colors.black,
      opacityShadow: 0.2,
      onClickTarget: (target) {
        final Map<GlobalKey, int> targetIndexMap = {
          _friendIconKey: 0,
          _postIconKey: 1,
          _missionIconKey: 2,
          _manitoIconKey: -1,
        };
        final newIndex = targetIndexMap[target.keyTarget];
        if (newIndex != null) {
          setState(() {
            _selectedIndex = newIndex + 1;
          });
        }
      },
    );
  }

  // 타겟 위젯
  TargetFocus _createTarget(GlobalKey keyTarget, String text) {
    return TargetFocus(
      keyTarget: keyTarget,
      alignSkip: Alignment.topRight,
      contents: [
        TargetContent(
          padding: EdgeInsets.only(
            left: 0.1 * width,
            right: 0.1 * width,
            bottom: 0.15 * width,
          ),
          align: ContentAlign.top,
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(0.04 * width),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(0.02 * width),
            ),
            child: Text(text, style: TextStyle(color: kDarkWalnut)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [_getScreen(0), _getScreen(1), _getScreen(2), _getScreen(3)],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: customBadgeIcon(
              _badgeController.badgeMap['friend_request']!,
              child: Icon(
                CustomIcons.user,
                key: _friendIconKey,
                size: 0.055 * width,
              ),
            ),
            label: context.tr('bottom_nav.friends'),
          ),
          BottomNavigationBarItem(
            icon: customBadgeIcon(
              _badgeController.badgePostCount,
              child: Icon(
                CustomIcons.flag_filled,
                key: _postIconKey,
                size: 0.075 * width,
              ),
            ),
            label: context.tr('bottom_nav.history'),
          ),
          BottomNavigationBarItem(
            icon: customBadgeIcon(
              _badgeController.badgeMissionCount,
              child: Icon(
                CustomIcons.star,
                key: _missionIconKey,
                size: 0.065 * width,
              ),
            ),
            label: context.tr('bottom_nav.sent_missions'),
          ),
          BottomNavigationBarItem(
            icon: customBadgeIcon(
              _badgeController.badgeMap['mission_propose']!,
              child: Transform.translate(
                offset: Offset(-0.003 * width, 0),
                child: Icon(
                  CustomIcons.scroll,
                  key: _manitoIconKey,
                  size: 0.06 * width,
                ),
              ),
            ),
            label: context.tr('bottom_nav.received_missions'),
          ),
        ],
      ),
    );
  }
}
