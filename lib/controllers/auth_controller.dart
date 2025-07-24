import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
      authScreenLaunchMode:
          GetPlatform.isAndroid
              ? LaunchMode.inAppBrowserView
              : LaunchMode.inAppWebView,
      // authScreenLaunchMode: LaunchMode.platformDefault,
      scopes: 'profile_nickname,account_email',
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

  /// Google 로그인 처리
  Future<void> loginWithGoogle() async {
    try {
      final String webClientId = dotenv.env["GOOGLE_OAUTH_WEB"]!;
      final String iosClientId = dotenv.env["GOOGLE_OAUTH_IOS"]!;
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
        scopes: const <String>['email'],
      );
      final googleUser = await googleSignIn.signIn();
      // 사용자 로그인 취소
      if (googleUser == null) {
        debugPrint('사용자 로그인 취소');
        return;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      // 엑세스 토큰 없음
      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      // 아이디 토큰 없음
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      // supabase 로그인
      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      Get.offAll(() => SplashScreen());
    } catch (e) {
      debugPrint('loginWithGoogle Error: $e');
    }
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
  Future<AuthResponse?> loginWithApple() async {
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
      } else if (e.code == AuthorizationErrorCode.unknown) {
        debugPrint('사용자 계정 미설정');
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

  /// Apple 로그인 처리 - 안드로이드
  Future<void> loginWithApple2() async {
    // Apple OAuth 로그인 시도
    await supabase.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'https://rkfdbtdicxarrctsvmif.supabase.co/auth/v1/callback',
      // authScreenLaunchMode: LaunchMode.externalApplication,
      // authScreenLaunchMode: LaunchMode.inAppBrowserView,
      authScreenLaunchMode: LaunchMode.inAppWebView,
    );

    supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      // 성공적으로 로그인이 완료된 경우
      if (event == AuthChangeEvent.signedIn) {
        debugPrint('Logged in with Apple');
        Get.offAll(() => SplashScreen());
      } else {
        debugPrint('Login failed');
      }
    });
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
    } catch (e) {
      debugPrint('deleteUser Error: $e');
    }
  }
}
