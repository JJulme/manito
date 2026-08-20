import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<Session?> getCurrentSession();
  Future<String> getKakaoLoginUrl();
  Future<void> exchangeKakaoCodeForSession(String code);
  Future<void> loginWithGoogle();
  Future<AuthResponse?> loginWithApple();
  Future<void> logout();
  Future<void> deleteUser();
  Stream<AuthState> get onAuthStateChange;
}
