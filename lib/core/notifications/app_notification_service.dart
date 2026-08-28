import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/friends/presentation/friends_provider.dart';
import '../../features/rooms/presentation/rooms_provider.dart';
import '../../features/feed/presentation/feed_provider.dart';
import '../../features/main/main_nav_screen.dart';
import '../providers.dart';
import '../router.dart';
import '../util/app_logger.dart';
import '../analytics/analytics_event.dart';
import '../analytics/analytics_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'models/app_notification.dart';

final appNotificationServiceProvider = Provider<AppNotificationService>((ref) {
  return AppNotificationService(ref);
});

class AppNotificationService {
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = flutterLocalNotificationsPlugin;

  bool _isInitialized = false;

  AppNotificationService(this._ref);

  /// FCM 및 로컬 알림 초기화
  Future<void> initialize({required String userId}) async {
    if (_isInitialized) return;

    try {
      AppLogger.i('Initializing AppNotificationService for user: $userId', tag: 'NOTIF');

      // 1. 알림 권한 요청
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        AppLogger.w('Notification permission not granted: ${settings.authorizationStatus}', tag: 'NOTIF');
      }

      await _fcm.setAutoInitEnabled(true);
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 2. iOS APNS 토큰 대기
      if (Platform.isIOS) {
        final apnsToken = await _fcm.getAPNSToken();
        AppLogger.d('APNS Token: $apnsToken', tag: 'NOTIF');
      }

      // 3. FCM 토큰 획득 및 Supabase DB 동기화
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveFCMToken(userId, token);
      }

      // 4. 토큰 갱신 리스너
      _fcm.onTokenRefresh.listen((newToken) async {
        await _saveFCMToken(userId, newToken);
      });

      // 5. 로컬 알림 초기화 및 탭 콜백 등록
      const androidInit = AndroidInitializationSettings('ic_notification');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payloadStr = response.payload;
          if (payloadStr != null && payloadStr.isNotEmpty) {
            try {
              final json = jsonDecode(payloadStr) as Map<String, dynamic>;
              final payload = AppNotificationPayload.fromJson(json);
              _invalidateRelevantProviders(payload);
              _handleNotificationTap(payload);
            } catch (e) {
              AppLogger.e('Failed to parse notification payload: $e', tag: 'NOTIF');
            }
          }
        },
      );

      // 6. 포그라운드 메시지 리스너
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        try {
          _handleForegroundMessage(message);
        } catch (e, s) {
          AppLogger.e('Error handling foreground FCM message: $e', tag: 'NOTIF', error: e, stackTrace: s);
        }
      });

      // 7. 백그라운드에서 알림 클릭하여 앱 열림 리스너
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        try {
          AppLogger.i('Notification opened from background: ${message.data}', tag: 'NOTIF');
          final payload = AppNotificationPayload.fromJson(message.data);
          _invalidateRelevantProviders(payload);
          _handleNotificationTap(payload);
        } catch (e, s) {
          AppLogger.e('Error handling background opened FCM message: $e', tag: 'NOTIF', error: e, stackTrace: s);
        }
      });

      // 8. 앱 완전 종료 상태에서 알림 클릭하여 실행된 경우 처리
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        try {
          AppLogger.i('App launched from terminated state via notification: ${initialMessage.data}', tag: 'NOTIF');
          final payload = AppNotificationPayload.fromJson(initialMessage.data);
          _invalidateRelevantProviders(payload);
          Future.delayed(const Duration(milliseconds: 600), () {
            _handleNotificationTap(payload);
          });
        } catch (e, s) {
          AppLogger.e('Error handling initial FCM message: $e', tag: 'NOTIF', error: e, stackTrace: s);
        }
      }

      _isInitialized = true;
      AppLogger.i('AppNotificationService initialized successfully', tag: 'NOTIF');
    } catch (e, s) {
      AppLogger.e('AppNotificationService initialization failed: $e', tag: 'NOTIF', error: e, stackTrace: s);
    }
  }

  /// Supabase users 테이블에 FCM 토큰 저장
  Future<void> _saveFCMToken(String userId, String token) async {
    try {
      await Supabase.instance.client.from('users').update({
        'fcm_token': token,
      }).eq('user_id', userId);
      AppLogger.i('FCM Token saved to DB for user: $userId', tag: 'NOTIF');
    } catch (e, s) {
      AppLogger.e('Failed to save FCM token to DB: $e', tag: 'NOTIF', error: e, stackTrace: s);
    }
  }

  /// 포그라운드(앱 켜짐) 메시지 수신 핸들러
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      AppLogger.i('Foreground push received: title=${message.notification?.title}, data=${message.data}', tag: 'NOTIF');

      final title = message.notification?.title ?? message.data['title']?.toString() ?? '마니또 알림';
      final body = message.notification?.body ?? message.data['body']?.toString() ?? '';
      final payload = AppNotificationPayload.fromJson(message.data);

      // 1. 해당 알림 타입에 맞는 Riverpod Provider 실시간 자동 갱신
      _invalidateRelevantProviders(payload);

      // 2. Android에서는 로컬 알림을 통해 상단 헤드업 배너를 띄웁니다.
      // (iOS는 setForegroundNotificationPresentationOptions에 의해 OS가 자체적으로 1개 띄우므로 중복 방지)
      if (Platform.isAndroid) {
        final notifId = (DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF);
        showLocalNotification(
          id: notifId,
          title: title,
          body: body,
          payload: jsonEncode(payload.toJson()),
        );
      }
    } catch (e, s) {
      AppLogger.e('Failed to process foreground message: $e', tag: 'NOTIF', error: e, stackTrace: s);
    }
  }

  /// 알림 타입에 따른 Riverpod Provider 실시간 무효화(새로고침) 디스패처
  void _invalidateRelevantProviders(AppNotificationPayload payload) {
    switch (payload.type) {
      case NotificationType.roomInvite:
        AppLogger.i('Invalidating receivedRoomInvitationsProvider for roomInvite', tag: 'NOTIF');
        _ref.invalidate(receivedRoomInvitationsProvider);
        _ref.invalidate(ongoingRoomsProvider);
        break;
      case NotificationType.roomInviteAccepted:
        if (payload.roomId != null) {
          _ref.invalidate(roomMembersProvider(payload.roomId!));
        }
        _ref.invalidate(ongoingRoomsProvider);
        break;
      case NotificationType.gameStarted:
        _ref.invalidate(ongoingRoomsProvider);
        if (payload.roomId != null) {
          _ref.invalidate(roomDetailsProvider(payload.roomId!));
        }
        break;
      case NotificationType.friendRequest:
      case NotificationType.friendAccepted:
        _ref.invalidate(acceptedFriendsProvider);
        _ref.invalidate(receivedFriendRequestsProvider);
        break;
      case NotificationType.commentCreated:
        final recordId = payload.extraData['record_id'];
        if (recordId != null) {
          final id = int.tryParse(recordId.toString());
          if (id != null) {
            _ref.invalidate(recordCommentsProvider(id));
          }
        }
        if (payload.roomId != null) {
          _ref.invalidate(roomRecordsProvider(payload.roomId!));
          _ref.invalidate(unreadCommentCountProvider(payload.roomId!));
        }
        _ref.invalidate(unreadCommentSummaryProvider);
        break;
      default:
        _ref.invalidate(ongoingRoomsProvider);
        break;
    }
  }

  /// OS 시스템 로컬 알림 팝업 (iOS 상단 네이티브 배너 / Android 헤드업)
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'default_notification_channel',
        '마니또 알림',
        channelDescription: '마니또 초대, 시작 및 미션 관련 알림을 수신합니다.',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_notification',
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final safeId = id & 0x7FFFFFFF;
      await _localNotifications.show(safeId, title, body, platformDetails, payload: payload);
    } catch (e, s) {
      AppLogger.e('Failed to show local notification: $e', tag: 'NOTIF', error: e, stackTrace: s);
    }
  }

  /// 알림 탭 시 화면 이동 (Deep-Link Navigation)
  void _handleNotificationTap(AppNotificationPayload payload) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = rootNavigatorKey.currentContext;
      if (context == null) return;

      final isFeedOrComment = payload.type == NotificationType.commentCreated ||
          payload.type == NotificationType.feedUploaded ||
          payload.type == NotificationType.gameEnded;

      if (isFeedOrComment) {
        _ref.read(selectedBottomTabProvider.notifier).state = 1;
      } else if (payload.type == NotificationType.roomInvite) {
        _ref.read(selectedBottomTabProvider.notifier).state = 0;
      }

      final targetRoute = payload.effectiveRoute;
      AppLogger.i('Handling notification tap: navigating to $targetRoute', tag: 'NOTIF');

      AnalyticsService.instance.logEvent(
        AnalyticsEvent.notificationClick,
        properties: {
          'notification_type': payload.type.name,
          'target_route': targetRoute,
          'room_id': payload.roomId,
        },
      );

      try {
        if (isFeedOrComment) {
          context.go('/bottom_nav2');
          context.push(targetRoute);
        } else {
          context.go(targetRoute);
        }
      } catch (e) {
        AppLogger.w('context navigation failed: $e', tag: 'NOTIF');
      }
    });
  }

  /// 마감 1분 전 및 마감 완료 로컬 백그라운드 푸시 알림 스케줄링
  Future<void> scheduleGameDeadlineNotifications({
    required String roomId,
    required String roomTitle,
    required DateTime gameEndTime,
  }) async {
    try {
      final now = DateTime.now();
      final oneMinBefore = gameEndTime.subtract(const Duration(minutes: 1));

      const androidDetails = AndroidNotificationDetails(
        'manito_deadline_channel',
        '마니또 마감 알림',
        channelDescription: '마니또 게임 마감 전 및 종료 알림을 수신합니다.',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_notification',
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 1. 마감 1분 전 알림 스케줄링
      if (oneMinBefore.isAfter(now)) {
        final id1 = (roomId.hashCode + 1) & 0x7FFFFFFF;
        final tzOneMinBefore = tz.TZDateTime.from(oneMinBefore, tz.local);
        final payload1 = jsonEncode({
          'type': 'GAME_DEADLINE_1MIN',
          'room_id': roomId,
          'route': '/rooms/$roomId/play',
        });

        await _safeZonedSchedule(
          id: id1,
          title: '⏰ 마감 1분 전!',
          body: '$roomTitle 마니또 마감 1분 전입니다! 미션과 추측을 서둘러 완료해주세요.',
          scheduledDate: tzOneMinBefore,
          notificationDetails: platformDetails,
          payload: payload1,
        );
        AppLogger.i('Scheduled 1-min before deadline notification for room $roomId at $oneMinBefore', tag: 'NOTIF');
      }

      // 2. 마감 완료 알림 스케줄링
      if (gameEndTime.isAfter(now)) {
        final id2 = (roomId.hashCode + 2) & 0x7FFFFFFF;
        final tzDeadline = tz.TZDateTime.from(gameEndTime, tz.local);
        final payload2 = jsonEncode({
          'type': 'GAME_COMPLETED',
          'room_id': roomId,
          'route': '/rooms/$roomId/result',
        });

        await _safeZonedSchedule(
          id: id2,
          title: '🎉 마니또 마감!',
          body: '$roomTitle 방이 마감되었습니다. 지금 마니또 결과를 확인해보세요!',
          scheduledDate: tzDeadline,
          notificationDetails: platformDetails,
          payload: payload2,
        );
        AppLogger.i('Scheduled deadline completion notification for room $roomId at $gameEndTime', tag: 'NOTIF');
      }
    } catch (e, s) {
      AppLogger.e('Failed to schedule deadline notifications: $e', tag: 'NOTIF', error: e, stackTrace: s);
    }
  }

  /// 안드로이드 Exact Alarm 권한 유무에 따른 안전한 스케줄 알림 등록 (Fallback 지원)
  Future<void> _safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required String payload,
  }) async {
    try {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        AppLogger.w('Exact alarm not permitted, falling back to inexactAllowWhileIdle: ${e.message}', tag: 'NOTIF');
        await _localNotifications.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
      } else {
        rethrow;
      }
    }
  }

  /// 마감 알림 즉시 발송 (마감 완료 시점)
  Future<void> showImmediateDeadlineCompleteNotification({
    required String roomId,
    required String roomTitle,
  }) async {
    final notifId = (roomId.hashCode + 2) & 0x7FFFFFFF;
    await showLocalNotification(
      id: notifId,
      title: '🎉 마니또 마감!',
      body: '$roomTitle 방이 마감되었습니다. 지금 마니또 결과를 확인해보세요!',
      payload: jsonEncode({
        'type': 'GAME_COMPLETED',
        'room_id': roomId,
        'route': '/result_feed/$roomId',
      }),
    );
  }

  /// 스케줄된 마감 알림 취소
  Future<void> cancelGameDeadlineNotifications(String roomId) async {
    try {
      final id1 = (roomId.hashCode + 1) & 0x7FFFFFFF;
      final id2 = (roomId.hashCode + 2) & 0x7FFFFFFF;
      await _localNotifications.cancel(id1);
      await _localNotifications.cancel(id2);
      AppLogger.i('Cancelled deadline notifications for room: $roomId', tag: 'NOTIF');
    } catch (e, s) {
      AppLogger.e('Failed to cancel deadline notifications: $e', tag: 'NOTIF', error: e, stackTrace: s);
    }
  }

  /// 로그아웃 시 FCM 토큰 정리
  Future<void> clearFCM(String userId) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': null})
          .eq('user_id', userId);

      await _fcm.deleteToken();
      _isInitialized = false;
      AppLogger.i('FCM token cleared for user: $userId', tag: 'NOTIF');
    } catch (e, s) {
      AppLogger.e('Failed to clear FCM token: $e', tag: 'NOTIF', error: e, stackTrace: s);
    }
  }
}
