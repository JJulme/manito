import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/badge/presentation/providers/badge_provider.dart';
import 'package:manito/core/error/error_provider.dart';
import 'package:manito/features_new/manito/presentation/providers/manito_provider.dart';
import 'package:manito/features_new/missions/presentation/providers/missions_provider.dart';
import 'package:manito/features_new/posts/presentation/providers/posts_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FCMService {
  final Ref _ref;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin;
  FCMService(this._ref, this._localNotificationsPlugin);

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _currentToken;
  // 토큰 가져오기
  String? get currentToken => _currentToken;

  Future<void> initalizeFCM({
    required String userId,
    Function(String, String)? onError,
  }) async {
    try {
      // 1. 권한 요청
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        onError?.call('error title', 'error message');
        return;
      }

      // 2. APNS 토큰 설정 (iOS)
      await _firebaseMessaging.getAPNSToken();
      // 3. FCM 토큰 가져오기 및 저장
      final fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $fcmToken');

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
      debugPrint('✅ FCM initialized successfully for user: $userId');
    } catch (e) {
      debugPrint('❌ FCM initialization failed: $e');
      _ref
          .read(errorProvider.notifier)
          .setError('FCM initialization failed: $e');
      // onError?.call(
      //   "bottom_nav.token_error_snack_title",
      //   "bottom_nav.token_error_snack_message",
      // );
    }
  }

  // FCM 토큰 Supabase 저장
  Future<void> _saveFCMToken(String userId, String fcmToken) async {
    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'fcm_token': fcmToken,
      });
      debugPrint(
        '✅ FCM token saved to database: ${fcmToken.substring(0, 20)}...',
      );
    } catch (e) {
      debugPrint('❌ Failed to save FCM token: $e');
      _ref
          .read(errorProvider.notifier)
          .setError('Failed to save FCM token: $e');
      rethrow;
    }
  }

  /// 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 Foreground message received:');
    debugPrint('  - Title: ${message.notification?.title}');
    debugPrint('  - Body: ${message.notification?.body}');
    debugPrint('  - Data: ${message.data}');
    // 여기서 앱 내 알림, 뱃지, 데이터 새로고침 등 처리
    // 예: 로컬 알림 표시, 상태 업데이트 등
    final messageType = message.data['type'];

    switch (messageType) {
      case 'friend_request':
        await _handleFriendRequest(message.data['sender_id']);
        break;
      case 'mission_propose':
        await _handleMissionPropose(message.data['id']);
        break;
      case 'update_mission_progress':
        await _handleMissionProgress(message.data['mission_id']);
        break;
      case 'update_mission_guess':
        await _handleMissionGuess(message.data['mission_id']);
        break;
      case 'update_mission_complete':
        await _handleMissionComplete(message.data['mission_id']);
        break;
      case 'insert_comment':
        await _handleNewComment(message);
        break;
      default:
        break;
    }
  }

  /// 친구 신청
  Future<void> _handleFriendRequest(String senderId) async {
    // 친구 신청 뱃지 +1
    _ref
        .read(badgeProvider.notifier)
        .incrementBadgeLocally('friend_request', senderId);

    await _showLocalNotification('friend_request');
  }

  /// 미션 제의
  Future<void> _handleMissionPropose(String proposeId) async {
    // 데이터 새로고침
    await _ref.read(manitoListProvider.notifier).fetchProposeList();
    // 마니또 제의 +1
    _ref
        .read(badgeProvider.notifier)
        .incrementBadgeLocally('mission_propose', proposeId);
    await _showLocalNotification('mission_propose');
  }

  /// 마니또가 미션 수락
  Future<void> _handleMissionProgress(String missionId) async {
    // 데이터 새로고침
    await _ref.read(missionListProvider.notifier).refresh();
    // 뱃지 증가
    _ref
        .read(badgeProvider.notifier)
        .incrementBadgeLocally('mission_accept', missionId);

    await _showLocalNotification('mission_accept');
  }

  /// 마니또가 미션 완료
  Future<void> _handleMissionGuess(String missionId) async {
    // 데이터 새로고침
    await _ref.read(missionListProvider.notifier).refresh();
    // 뱃지 증가
    _ref
        .read(badgeProvider.notifier)
        .incrementBadgeLocally('mission_guess', missionId);

    await _showLocalNotification('mission_guess');
  }

  /// 생성자가 추측 완료
  Future<void> _handleMissionComplete(String missionId) async {
    // 데이터 새로고침
    await _ref.read(manitoListProvider.notifier).fetchGuessList();
    await _ref.read(postsProvider.notifier).refresh();
    // 뱃지 증가
    _ref
        .read(badgeProvider.notifier)
        .incrementBadgeLocally('post_comment', missionId);

    await _showLocalNotification('mission_complete');
  }

  /// 새로운 댓글
  Future<void> _handleNewComment(RemoteMessage message) async {
    final missionId = message.data['mission_id'];
    final senderName = message.notification?.title ?? '알 수 없음';
    final commentText = message.notification?.body ?? '';
    _ref
        .read(badgeProvider.notifier)
        .incrementBadgeLocally('post_comment', missionId);

    // 댓글 알림 표시
    await _showCommentNotification(
      missionId: missionId,
      senderName: senderName,
      commentText: commentText,
    );
  }

  // 로컬 알림 표시
  Future<void> _showLocalNotification(String keySuffix) async {
    try {
      final String titleKey = "firebase_handler.${keySuffix}_title";
      final String bodyKey = "firebase_handler.${keySuffix}_body";

      // 번역 가져오기
      final notificationTitle = titleKey.tr();
      final notificationMessage = bodyKey.tr();

      // Android
      const androidNotificationDetails = AndroidNotificationDetails(
        'default_channel',
        'Default Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );

      // iOS
      const iOSNotificationDetails = DarwinNotificationDetails();

      const platformChannelSpecifics = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iOSNotificationDetails,
      );

      await _localNotificationsPlugin.show(
        _generateNotificationId(keySuffix),
        notificationTitle,
        notificationMessage,
        platformChannelSpecifics,
      );
    } catch (e) {
      debugPrint('Show notification error: $e');
    }
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
    } catch (e) {
      debugPrint('Show comment notification error: $e');
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
      // 서버에서 토큰 제거
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': null})
          .eq('id', userId);

      await _firebaseMessaging.deleteToken();

      _currentToken = null;
      debugPrint('✅ FCM token cleared for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to clear FCM token: $e');
      _ref
          .read(errorProvider.notifier)
          .setError('Failed to clear FCM token: $e');
    }
  }
}
