import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;
  AuthService(this._supabase);

  // ✅ 현재 세션 가져오기
  Future<Session?> getCurrentSession() async {
    try {
      return _supabase.auth.currentSession;
    } catch (e) {
      debugPrint('getCurrentSession Error: $e');
      return null;
    }
  }

  /// Kakao 로그인 처리 - 사용안함
  Future<void> loginWithKakao() async {
    // Kakao OAuth 로그인 시도
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.kakao,
      redirectTo: 'kakao1a36ff49b64f62a81bd117e504fe332b://oauth',
      // authScreenLaunchMode: LaunchMode.externalApplication,
      // authScreenLaunchMode: LaunchMode.inAppBrowserView,
      authScreenLaunchMode:
          defaultTargetPlatform == TargetPlatform.android
              ? LaunchMode.inAppBrowserView
              : LaunchMode.inAppWebView,
      // authScreenLaunchMode: LaunchMode.platformDefault,
      scopes: 'profile_nickname,account_email',
    );
  }

  /// Kakao webview 로그인
  Future<String> getKakaoLoginUrl() async {
    final response = await _supabase.auth.getOAuthSignInUrl(
      provider: OAuthProvider.kakao,
      queryParams: {'scope': 'profile_nickname,account_email'},
    );
    return response.url;
  }

  /// 코드를 교환해 세션을 얻는 함수
  Future<void> exchangeKakaoCodeForSession(String code) async {
    await _supabase.auth.exchangeCodeForSession(code);
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
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      debugPrint('loginWithGoogle Error: $e');
    }
  }

  /// Apple 로그인 처리
  Future<AuthResponse?> loginWithApple() async {
    try {
      final rawNonce = _supabase.auth.generateRawNonce();
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
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      return response;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('사용자 로그인 취소');
      } else if (e.code == AuthorizationErrorCode.unknown) {
        debugPrint('사용자 계정 미설정');
      } else {
        debugPrint('로그인 실패: $e');
      }
    } catch (e) {
      debugPrint('signInWithApple Error: $e');
    }
    return null;
  }

  // 로그아웃 처리
  Future<void> logout() async {
    try {
      await CookieManager.instance().deleteAllCookies();
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('logout Error: $e');
    }
  }

  // 계정 삭제
  Future<void> deleteUser() async {
    try {
      await CookieManager.instance().deleteAllCookies();
      await _supabase.rpc('delete_user');
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('deleteUser Error: $e');
    }
  }
}
