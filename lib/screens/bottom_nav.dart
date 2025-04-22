import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/badge_controller.dart';
import 'package:manito/firebase_handler.dart';
import 'package:manito/screens/friend/friends_screen.dart';
import 'package:manito/screens/manito/manito_screen.dart';
import 'package:manito/screens/mission/mission_screen.dart';
import 'package:manito/screens/post/post_screen.dart';
import 'package:manito/widgets/common/custom_badge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bottom Nav Bar
class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> with WidgetsBindingObserver {
  final BadgeController _badgeController = Get.find<BadgeController>();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 등록
    _handleFCMToken();
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
      await _badgeController.loadBadgeState();
    }
  }

  /// 토큰 저장
  Future<void> _handleFCMToken() async {
    try {
      // FCM(푸시 알림) 권한 요청
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        Get.snackbar('알림 권한', '알림을 받으려면 설정에서 알림을 활성화해야 합니다.');
      }
      // late String? fcmToken;
      // // FCM 토큰 가져오기
      // if (GetPlatform.isAndroid) {
      //   // android의 경우 APNs 토큰 요청
      //   fcmToken = await FirebaseMessaging.instance.getToken();
      // } else {
      //   // iOS의 경우 APNs 토큰 요청
      //   fcmToken = await FirebaseMessaging.instance.getAPNSToken();
      // }
      await FirebaseMessaging.instance.getAPNSToken();
      final fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint('fcm token: $fcmToken');

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
      Get.snackbar('오류', 'FCM 토큰 오류');
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

  /// 바텀 네비게이션 인덱스
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    FriendsScreen(),
    PostScreen(),
    MissionScreen(),
    ManitoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 2) {
            _badgeController.clearMission();
          } else if (index == 3) {
            _badgeController.clearMissionPropose();
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: badgeIcon(
              _badgeController.friendRequestBadge,
              Icon(Icons.person_rounded),
            ),
            label: '친구',
          ),
          BottomNavigationBarItem(
            icon: badgeIcon(
              _badgeController.allPostBadge,
              Icon(Icons.chat_rounded),
            ),
            label: '게시물',
          ),
          BottomNavigationBarItem(
            icon: badgeIcon(
              _badgeController.missionBadge,
              Icon(Icons.mail_rounded),
            ),
            label: '미션',
          ),
          BottomNavigationBarItem(
            icon: badgeIcon(
              _badgeController.missonProposeBadge,
              Icon(Icons.list_alt),
            ),
            label: '마니또',
          ),
        ],
      ),
    );
  }
}
