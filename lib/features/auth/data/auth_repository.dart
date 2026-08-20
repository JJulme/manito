import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  Future<Session?> getCurrentSession() async {
    try {
      final session = _supabase.auth.currentSession;
      AppLogger.d('getCurrentSession: ${session?.user.id}', tag: 'AUTH');
      return session;
    } catch (e, s) {
      AppLogger.e('getCurrentSession Error: $e', tag: 'AUTH', error: e, stackTrace: s);
      return null;
    }
  }

  Future<String> getKakaoLoginUrl() async {
    final response = await _supabase.auth.getOAuthSignInUrl(
      provider: OAuthProvider.kakao,
      queryParams: {'scope': 'profile_nickname,account_email'},
    );
    AppLogger.i('Kakao Login URL generated', tag: 'AUTH');
    return response.url;
  }

  Future<void> exchangeKakaoCodeForSession(String code) async {
    try {
      AppLogger.i('Exchanging Kakao code for session...', tag: 'AUTH');
      await _supabase.auth.exchangeCodeForSession(code);
      AppLogger.i('Kakao session exchange successful', tag: 'AUTH');
    } catch (e, s) {
      AppLogger.e('exchangeKakaoCodeForSession Error: $e', tag: 'AUTH', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      AppLogger.i('Starting Google Sign-In...', tag: 'AUTH');
      final String webClientId = dotenv.env["GOOGLE_OAUTH_WEB"] ?? '';
      final String iosClientId = dotenv.env["GOOGLE_OAUTH_IOS"] ?? '';
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
        scopes: const <String>['email'],
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        AppLogger.w('사용자 구글 로그인 취소', tag: 'AUTH');
        return;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      AppLogger.i('Google Sign-In successful for ${googleUser.email}', tag: 'AUTH');
    } catch (e, s) {
      AppLogger.e('loginWithGoogle Error: $e', tag: 'AUTH', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<AuthResponse?> loginWithApple() async {
    try {
      AppLogger.i('Starting Apple Sign-In...', tag: 'AUTH');
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
      AppLogger.i('Apple Sign-In successful', tag: 'AUTH');
      return response;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        AppLogger.w('사용자 애플 로그인 취소', tag: 'AUTH');
      } else if (e.code == AuthorizationErrorCode.unknown) {
        AppLogger.w('사용자 애플 계정 미설정', tag: 'AUTH');
      } else {
        AppLogger.e('애플 로그인 실패: $e', tag: 'AUTH');
      }
    } catch (e, s) {
      AppLogger.e('signInWithApple Error: $e', tag: 'AUTH', error: e, stackTrace: s);
      rethrow;
    }
    return null;
  }

  Future<void> logout() async {
    try {
      AppLogger.i('Logging out user...', tag: 'AUTH');
      try {
        await CookieManager.instance().deleteAllCookies();
      } catch (cookieErr) {
        AppLogger.w('CookieManager clean skipped: $cookieErr', tag: 'AUTH');
      }
      await _supabase.auth.signOut();
      AppLogger.i('Logout completed successfully', tag: 'AUTH');
    } catch (e, s) {
      AppLogger.e('logout Error: $e', tag: 'AUTH', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> deleteUser() async {
    try {
      AppLogger.w('Deleting user account...', tag: 'AUTH');
      try {
        await CookieManager.instance().deleteAllCookies();
      } catch (cookieErr) {
        AppLogger.w('CookieManager clean skipped: $cookieErr', tag: 'AUTH');
      }
      await _supabase.rpc('delete_user');
      await _supabase.auth.signOut();
      AppLogger.i('User account deleted and signed out', tag: 'AUTH');
    } catch (e, s) {
      AppLogger.e('deleteUser Error: $e', tag: 'AUTH', error: e, stackTrace: s);
      rethrow;
    }
  }
}
