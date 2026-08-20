import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/notifications/app_notification_service.dart';
import 'package:manito/core/notifications/realtime_notification_listener.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final fcmListenerProvider = Provider<FCMListener>((ref) {
  return FCMListener(ref);
});

class FCMListener {
  final Ref _ref;
  String? _lastUserId;

  FCMListener(this._ref) {
    _init();
  }

  void _init() {
    _ref.listen<User?>(
      currentUserProvider,
      (previous, current) async {
        if (current != null) {
          await _handleUserLoggedIn(current);
        } else {
          await _handleUserLoggedOut();
        }
      },
    );

    _ref.listen<AsyncValue<AuthState>>(
      authStateProvider,
      (previous, current) async {
        current.when(
          data: (authState) async {
            final user = authState.session?.user;
            if (user != null) {
              await _handleUserLoggedIn(user);
            } else {
              await _handleUserLoggedOut();
            }
          },
          loading: () {},
          error: (error, stackTrace) async {
            // 일시적인 네트워크/DNS 단절인 경우 로그아웃 처리하지 않고 대기
            final errStr = error.toString();
            if (error is AuthRetryableFetchException ||
                errStr.contains('SocketException') ||
                errStr.contains('Failed host lookup') ||
                errStr.contains('Network is unreachable')) {
              AppLogger.w('FCM: 일시적인 네트워크 단절로 인증 상태 확인 지연: $error', tag: 'FCM');
              return;
            }

            AppLogger.e('Auth state error, clearing notifications: $error', tag: 'FCM', error: error, stackTrace: stackTrace);
            await _handleUserLoggedOut();
          },
        );
      },
    );

    // 앱 시작 시 이미 로그인되어 있는 경우 비동기로 안전하게 초기화
    Future.microtask(() async {
      final initialUser = Supabase.instance.client.auth.currentUser ?? _ref.read(currentUserProvider);
      if (initialUser != null) {
        await _handleUserLoggedIn(initialUser);
      }
    });
  }

  Future<void> _handleUserLoggedIn(User user) async {
    if (_lastUserId == user.id) return;
    _lastUserId = user.id;
    AppLogger.i('User logged in: ${user.id}', tag: 'FCM');

    try {
      // 1. 전역 알림 서비스 초기화 (FCM + Local Notification + DeepLink Navigation)
      final notifService = _ref.read(appNotificationServiceProvider);
      await notifService.initialize(userId: user.id);

      // 2. 포그라운드 실시간 수신 리스너 시작 (Supabase Realtime)
      final realtimeListener = _ref.read(realtimeNotificationListenerProvider);
      realtimeListener.startListening(user.id);

      AppLogger.i('Notification & Realtime setup completed for user: ${user.id}', tag: 'FCM');
    } catch (e, s) {
      _lastUserId = null;
      AppLogger.e('Notification setup failed for user ${user.id}: $e', tag: 'FCM', error: e, stackTrace: s);
    }
  }

  Future<void> _handleUserLoggedOut() async {
    if (_lastUserId == null) return;

    AppLogger.i('User logged out: $_lastUserId', tag: 'FCM');

    try {
      final notifService = _ref.read(appNotificationServiceProvider);
      await notifService.clearFCM(_lastUserId!);

      final realtimeListener = _ref.read(realtimeNotificationListenerProvider);
      realtimeListener.stopListening();

      _lastUserId = null;
      AppLogger.i('Notification cleanup completed', tag: 'FCM');
    } catch (e, s) {
      AppLogger.e('Notification cleanup failed: $e', tag: 'FCM', error: e, stackTrace: s);
    }
  }
}
