import 'dart:convert';

/// 인앱 / 푸시 알림 타입 정의
enum NotificationType {
  /// 친구 요청 도착
  friendRequest,

  /// 친구 요청 수락됨
  friendAccepted,

  /// 방 초대 도착
  roomInvite,

  /// 방 초대 수락됨
  roomInviteAccepted,

  /// 게임 시작 알림
  gameStarted,

  /// 마니또 매칭 결과 안내
  manitoAssigned,

  /// 마니또 마감 임박 알림 (종료 1시간 / 1분 전 등)
  gameDeadline,

  /// 마니또 게임 종료 및 결과 공개 알림
  gameEnded,

  /// 미션 인증글 작성 알림 (마니또가 활동함)
  feedUploaded,

  /// 인증글에 댓글 등록 알림
  commentCreated,

  /// 일반 시스템 / 공지 알림
  system,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.friendRequest:
        return 'friend_request';
      case NotificationType.friendAccepted:
        return 'friend_accepted';
      case NotificationType.roomInvite:
        return 'room_invite';
      case NotificationType.roomInviteAccepted:
        return 'room_invite_accepted';
      case NotificationType.gameStarted:
        return 'game_started';
      case NotificationType.manitoAssigned:
        return 'manito_assigned';
      case NotificationType.gameDeadline:
        return 'game_deadline';
      case NotificationType.gameEnded:
        return 'game_ended';
      case NotificationType.feedUploaded:
        return 'feed_uploaded';
      case NotificationType.commentCreated:
        return 'comment_created';
      case NotificationType.system:
        return 'system';
    }
  }

  static NotificationType fromString(String? val) {
    switch (val) {
      case 'friend_request':
        return NotificationType.friendRequest;
      case 'friend_accepted':
      case 'friend_accept':
        return NotificationType.friendAccepted;
      case 'room_invite':
        return NotificationType.roomInvite;
      case 'room_invite_accepted':
      case 'room_join':
        return NotificationType.roomInviteAccepted;
      case 'game_started':
      case 'game_start':
        return NotificationType.gameStarted;
      case 'manito_assigned':
        return NotificationType.manitoAssigned;
      case 'game_deadline':
        return NotificationType.gameDeadline;
      case 'game_ended':
        return NotificationType.gameEnded;
      case 'feed_uploaded':
      case 'mission_proof':
        return NotificationType.feedUploaded;
      case 'comment_created':
      case 'new_comment':
        return NotificationType.commentCreated;
      default:
        return NotificationType.system;
    }
  }
}

/// 알림 페이로드 데이터 모델
class AppNotificationPayload {
  final NotificationType type;
  final String? title;
  final String? body;
  final String? roomId;
  final String? recordId;
  final String? senderId;
  final String? senderName;
  final Map<String, dynamic> extraData;

  const AppNotificationPayload({
    required this.type,
    this.title,
    this.body,
    this.roomId,
    this.recordId,
    this.senderId,
    this.senderName,
    this.extraData = const {},
  });

  factory AppNotificationPayload.fromJson(Map<String, dynamic> json) {
    final extra = json['extraData'] ?? json['extra'];
    Map<String, dynamic> parsedExtra = {};
    if (extra is Map<String, dynamic>) {
      parsedExtra = extra;
    } else if (extra is String) {
      try {
        parsedExtra = jsonDecode(extra) as Map<String, dynamic>;
      } catch (_) {}
    }

    return AppNotificationPayload(
      type: NotificationTypeExtension.fromString(json['type']?.toString()),
      title: json['title']?.toString(),
      body: json['body']?.toString(),
      roomId: json['room_id']?.toString() ?? json['roomId']?.toString(),
      recordId: json['record_id']?.toString() ?? json['recordId']?.toString(),
      senderId: json['sender_id']?.toString() ?? json['senderId']?.toString(),
      senderName: json['sender_name']?.toString() ?? json['senderName']?.toString(),
      extraData: parsedExtra,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (roomId != null) 'room_id': roomId,
      if (recordId != null) 'record_id': recordId,
      if (senderId != null) 'sender_id': senderId,
      if (senderName != null) 'sender_name': senderName,
      if (extraData.isNotEmpty) 'extraData': extraData,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  String get effectiveRoute {
    switch (type) {
      case NotificationType.roomInvite:
        return '/bottom_nav2';
      case NotificationType.roomInviteAccepted:
        return roomId != null ? '/lobby/$roomId' : '/bottom_nav2';
      case NotificationType.gameStarted:
        return roomId != null ? '/game/$roomId' : '/bottom_nav2';
      case NotificationType.gameEnded:
      case NotificationType.commentCreated:
      case NotificationType.feedUploaded:
        return roomId != null ? '/result_feed/$roomId' : '/bottom_nav2';
      case NotificationType.friendRequest:
      case NotificationType.friendAccepted:
        return '/add_friend';
      default:
        return '/bottom_nav2';
    }
  }
}
