import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:manito/screens/login_screen.dart';
import 'package:manito/screens/splash_screen.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final supabase = Supabase.instance.client;

  /// Kakao 로그인 처리
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

  /// Apple 로그인 처리
  Future<AuthResponse?> signInWithApple() async {
    try {
      final rawNonce = supabase.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException(
          'Could not find ID Token from generated credential.',
        );
      }
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      Get.offAll(() => SplashScreen());
      return response;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('사용자 로그인 취소');
      } else {
        customSnackbar(title: '로그인 실패', message: '오류 코드: ${e.code}');
        debugPrint('로그인 실패: $e');
      }
    } catch (e) {
      customSnackbar(title: '로그인 오류', message: '알 수 없는 오류: $e');
      debugPrint('signInWithApple Error: $e');
    }
    return null;
  }

  // 로그아웃 처리
  Future<void> logout() async {
    try {
      await CookieManager.instance().deleteAllCookies();
      await supabase.auth.signOut();
      Get.offAll(() => LoginScreen());
    } catch (e) {
      debugPrint('logout Error: $e');
    }
  }

  // 계정 삭제
  Future<void> deleteUser() async {
    try {
      await CookieManager.instance().deleteAllCookies();
      await supabase.rpc('delete_user');
      Get.offAll(() => LoginScreen());
      customSnackbar(title: '계정 삭제 완료', message: '계정이 삭제 되었습니다.');
    } catch (e) {
      debugPrint('deleteUser Error: $e');
    }
  }
}
