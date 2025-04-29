import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:manito/screens/login_screen.dart';
import 'package:manito/screens/splash_screen.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final supabase = Supabase.instance.client;

  // Kakao 로그인 처리
  Future<void> loginWithKakao() async {
    // Kakao OAuth 로그인 시도
    await supabase.auth.signInWithOAuth(
      OAuthProvider.kakao,
      redirectTo: 'kakao1a36ff49b64f62a81bd117e504fe332b://oauth',
      // authScreenLaunchMode: LaunchMode.externalApplication,
      // authScreenLaunchMode: LaunchMode.inAppBrowserView,
      authScreenLaunchMode: LaunchMode.inAppWebView,
      // authScreenLaunchMode: LaunchMode.platformDefault,
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

  // Future<void> loginWithKakao() async {
  //   // Kakao OAuth 로그인 시도
  //   final oauthResponse = await supabase.auth.getOAuthSignInUrl(
  //     provider: OAuthProvider.kakao,
  //     redirectTo: 'kakao1a36ff49b64f62a81bd117e504fe332b://oauth',
  //   );
  //   print('oauthResponse: ${oauthResponse.url}');

  //   supabase.auth.onAuthStateChange.listen((data) async {
  //     final AuthChangeEvent event = data.event;
  //     // 성공적으로 로그인이 완료된 경우
  //     if (event == AuthChangeEvent.signedIn) {
  //       debugPrint('Logged in with Kakao');
  //       Get.offAll(() => SplashScreen());
  //     } else {
  //       debugPrint('Login failed');
  //     }
  //   });
  // }

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
      await supabase.rpc('delete_user');
      Get.offAll(() => LoginScreen());
      customSnackbar(title: '계정 삭제 완료', message: '계정이 삭제 되었습니다.');
    } catch (e) {
      debugPrint('deleteUser Error: $e');
    }
  }
}
