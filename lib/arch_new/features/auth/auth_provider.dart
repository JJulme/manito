import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/arch_new/core/providers.dart';
import 'package:manito/arch_new/core/router.dart';
import 'package:manito/arch_new/features/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// AuthService 제공하는 프로바이더
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseProvider));
});

// Supabase의 인증 상태 변화를 스트림으로 제공하는 StreamProvider
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

//
final authNotifierProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier(ref);
});

// 인증 노티파이어
class AuthNotifier extends StateNotifier<bool> {
  final Ref _ref;
  AuthNotifier(this._ref) : super(false) {
    // authStateChagesProvider 리슨하여 화면 이동
    _ref.listen<AsyncValue<AuthState>>(authStateChangesProvider, (
      previous,
      next,
    ) {
      // 로그인 화면 이동
      if (next.value?.event == AuthChangeEvent.signedIn) {
        _ref.read(routerProvider).go('/bottom_nav');
        debugPrint('로그인 성공');
      }
      // 로그아웃 화면 이동
      else if (next.value?.event == AuthChangeEvent.signedOut) {
        _ref.read(routerProvider).go('/login');
        debugPrint('로그인 실패');
      }
    });
  }

  // 카카오 로그인 - 사용안함
  Future<void> loginWithKakao() async {
    state = true;
    try {
      await _ref.read(authServiceProvider).loginWithKakao();
    } finally {
      state = false;
    }
  }

  //
  Future<void> exchangeKakaoCodeForSession(String code) async {
    state = true;
    try {
      final service = _ref.read(authServiceProvider);
      await service.exchangeKakaoCodeForSession(code);
    } finally {
      state = false;
    }
  }

  // 구글 로그인
  Future<void> loginWithGoogle() async {
    state = true;
    try {
      await _ref.read(authServiceProvider).loginWithGoogle();
    } finally {
      state = false;
    }
  }

  // 애플 로그인
  Future<void> loginWithApple() async {
    state = true;
    try {
      await _ref.read(authServiceProvider).loginWithApple();
    } finally {
      state = false;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    state = true;
    try {
      await _ref.read(authServiceProvider).logout();
    } finally {
      state = false;
    }
  }

  // 계정 삭제
  Future<void> deleteUser() async {
    state = true;
    try {
      await _ref.read(authServiceProvider).deleteUser();
    } finally {
      state = false;
    }
  }
}
