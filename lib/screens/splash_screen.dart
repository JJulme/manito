import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/badge_controller.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/controllers/manito_controller.dart';
import 'package:manito/controllers/mission_controller.dart';
import 'package:manito/controllers/post_controller.dart';
import 'package:manito/screens/login_screen.dart';
import 'package:manito/screens/bottom_nav.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  // 초기화와 리디렉션을 위한 함수
  Future<void> _redirect() async {
    // 안정성을 위해서 UI 빌드가 완료되길 기다리는 코드
    await Future.delayed(Duration.zero);

    // 위젯이 현재 트리에 연결되어 있는지 확인
    if (!mounted) {
      return; // 연결이 안되었다면 진행하지 않음
    }

    final session = Supabase.instance.client.auth.currentSession;
    // 로그인 세션이 있다면
    if (session != null) {
      // 친구들 프로필 정보 먼저 가져오기
      final friendsController = Get.put(FriendsController(), permanent: true);
      await friendsController.getProfile();
      await friendsController.fetchFriendList();
      final badgeContorller = Get.put(BadgeController(), permanent: true);
      await badgeContorller.fetchExistingBadges();
      Get.put(ManitoController(), permanent: true);
      Get.put(MissionController(), permanent: true);
      Get.put(PostController(), permanent: true);
      // 런처 스플래쉬 화면 제거
      FlutterNativeSplash.remove();
      // 메인 화면으로 이동
      Get.offAll(() => BottomNav(), transition: Transition.fadeIn);
    }
    // 로그인 세션이 없다면
    else {
      // 런처 스플래쉬 화면 제거
      FlutterNativeSplash.remove();
      debugPrint('로그인 세션 없음');
      Get.offAll(() => LoginScreen(), transition: Transition.fade);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Image.asset(
            'assets/images/manito_dog.png',
            width: 0.65 * width,
            height: 0.65 * width,
          ),
        ),
      ),
    );
  }
}
