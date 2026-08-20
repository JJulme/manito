import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/error/error_provider.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService(ref);
});

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      flutterLocalNotificationsPlugin;
  final Ref _ref;
  String? _currentToken;

  FCMService(this._ref);

  /// FCM 초기화
  Future<void> initalizeFCM({
    required String userId,
    void Function(String title, String message)? onError,
  }) async {
    try {
      AppLogger.i('Initializing FCM for user: $userId', tag: 'FCM');

      // 1. 권한 요청
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        AppLogger.w('FCM permission not authorized: ${settings.authorizationStatus}', tag: 'FCM');
        return;
      }

      // 2. APNS 토큰 설정 (iOS)
      if (Platform.isIOS) {
        await _firebaseMessaging.getAPNSToken();
      }

      // 3. FCM 토큰 가져오기 및 저장
      final fcmToken = await _firebaseMessaging.getToken();
      AppLogger.d('FCM Token: $fcmToken', tag: 'FCM');

      if (fcmToken != null) {
        _currentToken = fcmToken;
        await _saveFCMToken(userId, fcmToken);
      }

      // 4. 토큰 갱신될 때 리스너 설정
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        _currentToken = newToken;
        await _saveFCMToken(userId, newToken);
      });

      // 5. 포그라운드 메시지 리스너 설정
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      AppLogger.i('FCM initialized successfully for user: $userId', tag: 'FCM');
    } catch (e, s) {
      AppLogger.e('FCM initialization failed: $e', tag: 'FCM', error: e, stackTrace: s);
      _ref
          .read(errorProvider.notifier)
          .setError('FCM initialization failed: $e');
    }
  }

  // FCM 토큰 Supabase 저장
  Future<void> _saveFCMToken(String userId, String fcmToken) async {
    try {
      await Supabase.instance.client.from('users').update({
        'fcm_token': fcmToken,
      }).eq('user_id', userId);
      AppLogger.i('FCM token saved to database for user: $userId', tag: 'FCM');
    } catch (e, s) {
      AppLogger.e('Failed to save FCM token: $e', tag: 'FCM', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.i(
      'Foreground message received: title=${message.notification?.title}, body=${message.notification?.body}, data=${message.data}',
      tag: 'FCM',
    );

    final messageType = message.data['type'];

    switch (messageType) {
      case 'friend_request':
        await _handleFriendRequest(message.data['sender_id']);
        break;
      case 'mission_propose':
        await _handleMissionPropose(message.data['id']);
        break;
      case 'update_mission_progress':
        break;
      case 'comment':
        await _showCommentNotification(
          missionId: message.data['mission_id'] ?? '',
          senderName: message.data['sender_name'] ?? '알림',
          commentText: message.data['comment_text'] ?? '',
        );
        break;
      default:
        AppLogger.d('Unhandled message type: $messageType', tag: 'FCM');
    }
  }

  /// 친구 요청 처리
  Future<void> _handleFriendRequest(String? senderId) async {
    if (senderId == null) return;
    AppLogger.d('Handling friend request notification: $senderId', tag: 'FCM');
  }

  /// 미션 제안 처리
  Future<void> _handleMissionPropose(String? missionId) async {
    if (missionId == null) return;
    AppLogger.d('Handling mission propose notification: $missionId', tag: 'FCM');
  }

  /// 댓글 알림 표시
  Future<void> _showCommentNotification({
    required String missionId,
    required String senderName,
    required String commentText,
  }) async {
    try {
      const androidNotificationDetails = AndroidNotificationDetails(
        'comment_channel',
        'Comment Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );

      const iOSNotificationDetails = DarwinNotificationDetails();

      const platformChannelSpecifics = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iOSNotificationDetails,
      );

      await _localNotificationsPlugin.show(
        _generateNotificationId('comment_$missionId'),
        senderName,
        commentText,
        platformChannelSpecifics,
      );
    } catch (e, s) {
      AppLogger.e('Show comment notification error: $e', tag: 'FCM', error: e, stackTrace: s);
    }
  }

  /// 알림 ID 생성
  int _generateNotificationId(String keySuffix) {
    final uniqueString =
        keySuffix + DateTime.now().millisecondsSinceEpoch.toString();
    return uniqueString.hashCode;
  }

  /// FCM 정리 (로그아웃 시 호출)
  Future<void> clearFCM(String userId) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': null})
          .eq('user_id', userId);

      await _firebaseMessaging.deleteToken();

      _currentToken = null;
      AppLogger.i('FCM token cleared for user: $userId', tag: 'FCM');
    } catch (e, s) {
      AppLogger.e('Failed to clear FCM token: $e', tag: 'FCM', error: e, stackTrace: s);
      _ref
          .read(errorProvider.notifier)
          .setError('Failed to clear FCM token: $e');
    }
  }
}
