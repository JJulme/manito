import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/features_new/auth/presentation/providers/auth_provider.dart';
import 'package:manito/core/fcm/fcm_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService(ref, FlutterLocalNotificationsPlugin());
});

final fcmListenerProvider = Provider<FCMListener>((ref) {
  return FCMListener(ref);
});

class FCMListener {
  final Ref _ref;
  String? _lastUserId;

  FCMListener(this._ref) {
    _startListening();
  }

  void _startListening() {
    _ref.listen<AsyncValue<AuthState>>(authStateChangesProvider, (
      previous,
      next,
    ) {
      _handleAuthStateChange(previous, next);
    });
  }

  Future<void> _handleAuthStateChange(
    AsyncValue<AuthState>? previous,
    AsyncValue<AuthState> next,
  ) async {
    await next.when(
      data: (authState) async {
        final user = authState.session?.user;
        // 로그인 상태
        if (user != null) {
          await _handleUserLoggedIn(user);
        }
        // 로그아웃 상태
        else {
          await _handleUserLoggedOut();
        }
      },
      loading: () {},
      error: (error, stackTrace) async {
        debugPrint('Auth state error, clearing FCM: $error');

        await _handleUserLoggedOut();
      },
    );
  }

  Future<void> _handleUserLoggedIn(User user) async {
    if (_lastUserId == user.id) return;
    debugPrint('🔑 User logged in: ${user.id}');

    try {
      final fcmService = _ref.read(fcmServiceProvider);
      await fcmService.initalizeFCM(
        userId: user.id,
        onError: (title, message) {},
      );
      _lastUserId = user.id;
      debugPrint('✅ FCM setup completed for user: ${user.id}');
    } catch (e) {
      debugPrint('❌ FCM setup failed for user ${user.id}: $e');
    }
  }

  Future<void> _handleUserLoggedOut() async {
    if (_lastUserId == null) return;

    debugPrint('🚪 User logged out: $_lastUserId');

    try {
      // FCM 토큰 정리
      final fcmService = _ref.read(fcmServiceProvider);
      await fcmService.clearFCM(_lastUserId!);
      _lastUserId = null;

      debugPrint('✅ FCM cleanup completed');
    } catch (e) {
      debugPrint('❌ FCM cleanup failed: $e');
    }
  }
}
