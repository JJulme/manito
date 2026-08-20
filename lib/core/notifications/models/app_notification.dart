import 'dart:convert';

/// 마니또 앱 전역 알림 타입 정의
enum NotificationType {
  roomInvite('ROOM_INVITE'),
  roomInviteAccepted('ROOM_INVITE_ACCEPTED'),
  gameStarted('GAME_STARTED'),
  friendRequest('FRIEND_REQUEST'),
  friendAccepted('FRIEND_ACCEPTED'),
  feedUploaded('FEED_UPLOADED'),
  commentCreated('COMMENT_CREATED'),
  deadlineApproaching('DEADLINE_APPROACHING'),
  gameEnded('GAME_ENDED'),
  general('GENERAL');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String? val) {
    if (val == null || val.isEmpty) return NotificationType.general;
    return NotificationType.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase() || e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => NotificationType.general,
    );
  }
}

/// 전역 알림 페이로드 모델
class AppNotificationPayload {
  final NotificationType type;
  final String title;
  final String body;
  final String? targetRoute;
  final String? roomId;
  final String? senderId;
  final String? senderName;
  final Map<String, dynamic> extraData;
  final DateTime createdAt;

  AppNotificationPayload({
    required this.type,
    required this.title,
    required this.body,
    this.targetRoute,
    this.roomId,
    this.senderId,
    this.senderName,
    Map<String, dynamic>? extraData,
    DateTime? createdAt,
  })  : extraData = extraData ?? {},
        createdAt = createdAt ?? DateTime.now();

  /// 딥링크 대상 라우트 계산 (지정된 targetRoute가 없으면 type 기반 기본 라우트 반환)
  String get effectiveRoute {
    if (targetRoute != null && targetRoute!.isNotEmpty) {
      return targetRoute!;
    }
    switch (type) {
      case NotificationType.roomInvite:
        return '/bottom_nav2';
      case NotificationType.roomInviteAccepted:
        return (roomId != null && roomId!.isNotEmpty) ? '/lobby/$roomId' : '/bottom_nav2';
      case NotificationType.gameStarted:
        return (roomId != null && roomId!.isNotEmpty) ? '/mission_setup/$roomId' : '/bottom_nav2';
      case NotificationType.feedUploaded:
      case NotificationType.commentCreated:
      case NotificationType.gameEnded:
        return (roomId != null && roomId!.isNotEmpty) ? '/result_feed/$roomId' : '/bottom_nav2';
      case NotificationType.deadlineApproaching:
        return (roomId != null && roomId!.isNotEmpty) ? '/game/$roomId' : '/bottom_nav2';
      case NotificationType.friendRequest:
      case NotificationType.friendAccepted:
        return '/bottom_nav2';
      case NotificationType.general:
        return '/bottom_nav2';
    }
  }

  static Map<String, dynamic> _parseExtraData(dynamic rawExtraData) {
    if (rawExtraData == null) return {};
    if (rawExtraData is Map) {
      return Map<String, dynamic>.from(rawExtraData);
    }
    if (rawExtraData is String && rawExtraData.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawExtraData);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    return {};
  }

  factory AppNotificationPayload.fromJson(Map<String, dynamic> json) {
    return AppNotificationPayload(
      type: NotificationType.fromString(json['type']?.toString()),
      title: json['title']?.toString() ?? '마니또 알림',
      body: json['body']?.toString() ?? '',
      targetRoute: json['target_route']?.toString() ?? json['route']?.toString(),
      roomId: json['room_id']?.toString(),
      senderId: json['sender_id']?.toString(),
      senderName: json['sender_name']?.toString(),
      extraData: _parseExtraData(json['extra_data']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'title': title,
      'body': body,
      'target_route': targetRoute ?? effectiveRoute,
      'room_id': roomId,
      'sender_id': senderId,
      'sender_name': senderName,
      'extra_data': extraData,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
