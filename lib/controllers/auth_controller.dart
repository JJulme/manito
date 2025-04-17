import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:manito/screens/login_screen.dart';
import 'package:manito/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final supabase = Supabase.instance.client;

  // Kakao 로그인 처리
  Future<void> loginWithKakao() async {
    // Kakao OAuth 로그인 시도
    await supabase.auth.signInWithOAuth(
      OAuthProvider.kakao,
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
    supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      // 성공적으로 로그인이 완료된 경우
      if (event == AuthChangeEvent.signedIn) {
        debugPrint('Logged in with Kakao');
        Get.offAll(() => SplashScreen());
      } else {
        debugPrint('Login failed');
      }
    });
  }

  // 로그아웃 처리
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      Get.offAll(() => LoginScreen());
    } catch (e) {
      debugPrint('logout Error: $e');
    }
  }

  // 계정 삭제
  Future<void> deleteUser() async {
    try {
      await supabase.auth.admin.deleteUser(supabase.auth.currentUser!.id);
      Get.offAll(() => LoginScreen());
    } catch (e) {
      debugPrint('deleteUser Error: $e');
    }
  }
}
