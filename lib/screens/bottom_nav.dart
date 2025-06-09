import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/badge_controller.dart';
import 'package:manito/custom_icons.dart';
import 'package:manito/firebase_handler.dart';
import 'package:manito/screens/friend/friends_screen.dart';
import 'package:manito/screens/manito/manito_screen.dart';
import 'package:manito/screens/mission/mission_screen.dart';
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

  final List<Widget> _screens = [
    FriendsScreen(),
    PostScreen(),
    MissionScreen(),
    ManitoScreen(),
  ];

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
    _initTutorial();
    if (mounted) {
      tutorialCoachMark.show(context: context);
    }
    // _checkAndShowTutorial();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 해제
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    // 앱이 포커스를 받을 때
    if (state == AppLifecycleState.resumed) {
      await _badgeController.fetchExistingBadges();
    }
  }

  /// 토큰 저장
  Future<void> _handleFCMToken() async {
    try {
      // FCM(푸시 알림) 권한 요청
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        customSnackbar(title: '알림 권한', message: '알림을 받으려면 설정에서 알림을 활성화해야 합니다.');
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
      customSnackbar(title: '오류', message: 'FCM 토큰 오류');
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
        _createTarget(_friendIconKey, '친구를 관리 할 수 있는 화면 입니다'),
        _createTarget(_postIconKey, '완료된 미션 기록을 확인할 수 있습니다'),
        _createTarget(
          _missionIconKey,
          '친구들에게 미션을 만들어서 보냅니다\n친구중에 한명이 당신의 마니또가 됩니다',
        ),
        _createTarget(_manitoIconKey, '친구들이 당신에게 보낸 미션을 확인하고 수행할 수 있습니다'),
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
      onFinish: () => print("튜토리얼 완료"),
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
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
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
        },
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
            label: '친구',
          ),
          BottomNavigationBarItem(
            icon: customBadgeIcon(
              _badgeController.badgePostCount,
              child: Icon(
                CustomIcons.comment,
                key: _postIconKey,
                size: 0.065 * width,
              ),
            ),
            label: '기록',
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
            label: '보낸미션',
          ),
          BottomNavigationBarItem(
            icon: customBadgeIcon(
              _badgeController.badgeMap['mission_propose']!,
              child: Icon(
                CustomIcons.scroll,
                key: _manitoIconKey,
                size: 0.06 * width,
              ),
            ),
            label: '받은미션',
          ),
        ],
      ),
    );
  }
}
