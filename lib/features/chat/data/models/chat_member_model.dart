import 'package:manito/core/models/user_model.dart';

class ChatMemberModel {
  final String roomId;
  final String userId;
  final DateTime joinedAt;
  final DateTime lastReadAt;
  final bool isActive;
  final String? customTitle;
  final UserModel? user;

  const ChatMemberModel({
    required this.roomId,
    required this.userId,
    required this.joinedAt,
    required this.lastReadAt,
    this.isActive = true,
    this.customTitle,
    this.user,
  });

  factory ChatMemberModel.fromJson(Map<String, dynamic> json) {
    return ChatMemberModel(
      roomId: json['room_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      joinedAt: json['joined_at'] != null
          ? (DateTime.tryParse(json['joined_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      lastReadAt: json['last_read_at'] != null
          ? (DateTime.tryParse(json['last_read_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      isActive: json['is_active'] as bool? ?? true,
      customTitle: json['custom_title'] as String?,
      user: json['users'] is Map<String, dynamic>
          ? UserModel.fromJson(json['users'] as Map<String, dynamic>)
          : (json['user'] is Map<String, dynamic>
              ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'user_id': userId,
      'joined_at': joinedAt.toUtc().toIso8601String(),
      'last_read_at': lastReadAt.toUtc().toIso8601String(),
      'is_active': isActive,
      'custom_title': customTitle,
    };
  }

  ChatMemberModel copyWith({
    DateTime? lastReadAt,
    bool? isActive,
    String? customTitle,
    UserModel? user,
  }) {
    return ChatMemberModel(
      roomId: roomId,
      userId: userId,
      joinedAt: joinedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      isActive: isActive ?? this.isActive,
      customTitle: customTitle ?? this.customTitle,
      user: user ?? this.user,
    );
  }
}
