import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../util/app_logger.dart';
import 'models/app_notification.dart';

final notificationSenderProvider = Provider<NotificationSender>((ref) {
  return NotificationSender();
});

/// 앱 전역에서 언제든 재사용 가능한 푸시 알림 발송 헬퍼
class NotificationSender {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 단일 사용자에게 알림 발송
  Future<void> sendToUser({
    required String targetUserId,
    required NotificationType type,
    required String title,
    required String body,
    String? roomId,
    String? senderId,
    String? senderName,
    Map<String, dynamic>? extraData,
  }) async {
    await sendToUsers(
      targetUserIds: [targetUserId],
      type: type,
      title: title,
      body: body,
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      extraData: extraData,
    );
  }

  /// 다중 사용자(목록)에게 알림 발송
  Future<void> sendToUsers({
    required List<String> targetUserIds,
    required NotificationType type,
    required String title,
    required String body,
    String? roomId,
    String? senderId,
    String? senderName,
    Map<String, dynamic>? extraData,
  }) async {
    if (targetUserIds.isEmpty) return;

    final currentUserId = senderId ?? _supabase.auth.currentUser?.id;

    final payload = AppNotificationPayload(
      type: type,
      title: title,
      body: body,
      roomId: roomId,
      senderId: currentUserId,
      senderName: senderName,
      extraData: extraData ?? {},
    );

    try {
      AppLogger.i('Sending notification [${type.value}] to ${targetUserIds.length} users: $title', tag: 'NOTIF_SENDER');

      // 1. 대상 사용자들의 FCM 토큰 조회
      final usersData = await _supabase
          .from('users')
          .select('user_id, fcm_token')
          .inFilter('user_id', targetUserIds);

      final tokens = (usersData as List)
          .map((u) => u['fcm_token'] as String?)
          .where((token) => token != null && token.isNotEmpty)
          .cast<String>()
          .toList();

      if (tokens.isEmpty) {
        AppLogger.w('No active FCM tokens found for target users: $targetUserIds', tag: 'NOTIF_SENDER');
        return;
      }

      // 2. Supabase Edge Function 'send-push-notification' 호출
      try {
        final res = await _supabase.functions.invoke(
          'send-push-notification',
          body: {
            'tokens': tokens,
            'title': payload.title,
            'body': payload.body,
            'data': payload.toJson(),
          },
        );
        AppLogger.i('Push notification dispatched to ${tokens.length} devices. Status: ${res.status}, Data: ${res.data}', tag: 'NOTIF_SENDER');
      } catch (funcError, funcStack) {
        AppLogger.e('Edge function invocation failed: $funcError', tag: 'NOTIF_SENDER', error: funcError, stackTrace: funcStack);
      }
    } catch (e, s) {
      AppLogger.e('Failed to send push notification: $e', tag: 'NOTIF_SENDER', error: e, stackTrace: s);
    }
  }

  /// [시나리오 1] 마니또 방 초대 알림 발송 헬퍼
  Future<void> sendRoomInvitationNotification({
    required String roomId,
    required List<String> invitedUserIds,
    required String hostName,
    required String roomTitle,
  }) async {
    await sendToUsers(
      targetUserIds: invitedUserIds,
      type: NotificationType.roomInvite,
      title: '📬 마니또 초대장이 도착했습니다!',
      body: '$hostName님이 마니또에 초대 했습니다.',
      roomId: roomId,
      senderName: hostName,
    );
  }

  /// [시나리오 2] 초대 수락 알림 발송 헬퍼 (방장에게 전송)
  Future<void> sendInviteAcceptedNotification({
    required String roomId,
    required String hostUserId,
    required String participantName,
    required String roomTitle,
  }) async {
    await sendToUser(
      targetUserId: hostUserId,
      type: NotificationType.roomInviteAccepted,
      title: '🎉 초대 수락 완료!',
      body: '$participantName님이 \'$roomTitle\' 초대를 수락했습니다.',
      roomId: roomId,
      senderName: participantName,
    );
  }

  /// [시나리오 3] 게임 시작 및 마니또 매칭 완료 알림 발송 헬퍼 (전체 멤버에게 전송)
  Future<void> sendGameStartedNotification({
    required String roomId,
    required List<String> memberUserIds,
    required String roomTitle,
  }) async {
    await sendToUsers(
      targetUserIds: memberUserIds,
      type: NotificationType.gameStarted,
      title: '🚀 마니또가 시작되었습니다!',
      body: '\'$roomTitle\' 게임이 시작되었습니다. 당신의 마니또를 확인하세요!',
      roomId: roomId,
    );
  }

  /// [시나리오 4] 댓글 등록 푸시 알림 발송 헬퍼 (댓글 작성자를 제외한 방 참여자 전원에게 전송)
  Future<void> sendCommentCreatedNotification({
    required String roomId,
    required int recordId,
    required List<String> targetUserIds,
    required String authorName,
    required String commentText,
  }) async {
    final previewText = commentText.length > 50
        ? '${commentText.substring(0, 50)}...'
        : commentText;

    await sendToUsers(
      targetUserIds: targetUserIds,
      type: NotificationType.commentCreated,
      title: '💬 $authorName님의 새로운 댓글',
      body: previewText,
      roomId: roomId,
      senderName: authorName,
      extraData: {
        'record_id': recordId,
        'route': '/result_feed/$roomId',
      },
    );
  }
}
