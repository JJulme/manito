import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return AuthRepository(supabase);
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.onAuthStateChange;
});

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    try {
      final session = await ref.read(authRepositoryProvider).getCurrentSession();
      return AuthState(
        session != null ? AuthChangeEvent.signedIn : AuthChangeEvent.signedOut,
        session,
      );
    } catch (e, s) {
      AppLogger.e('AuthNotifier Error: $e', tag: 'AUTH', error: e, stackTrace: s);
      return AuthState(AuthChangeEvent.signedOut, null);
    }
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).loginWithGoogle();
      final session = await ref.read(authRepositoryProvider).getCurrentSession();
      return AuthState(AuthChangeEvent.signedIn, session);
    });
  }

  Future<void> loginWithApple() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).loginWithApple();
      final session = await ref.read(authRepositoryProvider).getCurrentSession();
      return AuthState(AuthChangeEvent.signedIn, session);
    });
  }

  Future<void> exchangeKakaoCodeForSession(String code) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).exchangeKakaoCodeForSession(code);
      final session = await ref.read(authRepositoryProvider).getCurrentSession();
      return AuthState(AuthChangeEvent.signedIn, session);
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).logout();
      return AuthState(AuthChangeEvent.signedOut, null);
    });
  }

  Future<void> deleteUser() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).deleteUser();
      return AuthState(AuthChangeEvent.signedOut, null);
    });
  }
}
