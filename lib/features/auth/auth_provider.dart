import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features/auth/auth_service.dart';
import 'package:manito/features/error/error_provider.dart';
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
// final authNotifierProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
//   return AuthNotifier(ref);
// });

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    try {
      // ✅ getCurrentSession 사용
      final session = await ref.read(authServiceProvider).getCurrentSession();

      return AuthState(
        session != null ? AuthChangeEvent.signedIn : AuthChangeEvent.signedOut,
        session,
      );
    } catch (e) {
      ref.read(errorProvider.notifier).setError('인증 상태 확인 실패: $e');
      return AuthState(AuthChangeEvent.signedOut, null);
    }
  }

  // 구글 로그인
  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).loginWithGoogle();

      // ✅ 새로운 세션 가져오기
      final session = await ref.read(authServiceProvider).getCurrentSession();

      return AuthState(AuthChangeEvent.signedIn, session);
    });
  }

  // 애플 로그인
  Future<void> loginWithApple() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).loginWithApple();

      final session = await ref.read(authServiceProvider).getCurrentSession();

      return AuthState(AuthChangeEvent.signedIn, session);
    });
  }

  // 카카오 로그인
  Future<void> exchangeKakaoCodeForSession(String code) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).exchangeKakaoCodeForSession(code);

      final session = await ref.read(authServiceProvider).getCurrentSession();

      return AuthState(AuthChangeEvent.signedIn, session);
    });
  }

  // 로그아웃
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).logout();

      return AuthState(AuthChangeEvent.signedOut, null);
    });
  }

  // 계정 삭제
  Future<void> deleteUser() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).deleteUser();

      return AuthState(AuthChangeEvent.signedOut, null);
    });
  }
}
