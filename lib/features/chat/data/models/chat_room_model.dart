import 'chat_member_model.dart';
import 'chat_message_model.dart';

enum ChatRoomType {
  direct('DIRECT'),
  group('GROUP');

  final String value;
  const ChatRoomType(this.value);

  static ChatRoomType fromString(String val) {
    return ChatRoomType.values.firstWhere(
      (e) => e.value == val.toUpperCase(),
      orElse: () => ChatRoomType.direct,
    );
  }
}

class ChatRoomModel {
  final String id;
  final ChatRoomType type;
  final String? title;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMemberModel> members;
  final ChatMessageModel? lastMessage;
  final int unreadCount;

  const ChatRoomModel({
    required this.id,
    required this.type,
    this.title,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.members = const [],
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ChatRoomModel.fromJson(
    Map<String, dynamic> json, {
    List<ChatMemberModel> members = const [],
    ChatMessageModel? lastMessage,
    int unreadCount = 0,
  }) {
    List<ChatMemberModel> parsedMembers = members;
    if (json['chat_members'] is List) {
      parsedMembers = (json['chat_members'] as List)
          .map((m) => ChatMemberModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    ChatMessageModel? parsedLastMsg = lastMessage;
    if (json['last_message'] is Map<String, dynamic>) {
      parsedLastMsg = ChatMessageModel.fromJson(json['last_message'] as Map<String, dynamic>);
    }

    return ChatRoomModel(
      id: json['id']?.toString() ?? '',
      type: ChatRoomType.fromString(json['type']?.toString() ?? 'DIRECT'),
      title: json['title'] as String?,
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      members: parsedMembers,
      lastMessage: parsedLastMsg,
      unreadCount: unreadCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'created_by': createdBy,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  ChatMemberModel? getOtherMember(String currentUserId) {
    if (type != ChatRoomType.direct) return null;
    return members.where((m) => m.userId != currentUserId).firstOrNull;
  }

  String getDisplayTitle(String currentUserId) {
    if (title != null && title!.trim().isNotEmpty) {
      return title!;
    }

    if (type == ChatRoomType.direct) {
      final other = getOtherMember(currentUserId);
      return other?.user?.name ?? '대화 상대 없음';
    } else {
      final otherMembers = members.where((m) => m.userId != currentUserId).toList();
      if (otherMembers.isEmpty) {
        return '그룹 대화방 (나만 있음)';
      }
      final names = otherMembers.map((m) => m.user?.name ?? '사용자').take(3).join(', ');
      final totalCount = members.length;
      return totalCount > 1 ? '$names ($totalCount)' : names;
    }
  }

  ChatRoomModel copyWith({
    List<ChatMemberModel>? members,
    ChatMessageModel? lastMessage,
    int? unreadCount,
  }) {
    return ChatRoomModel(
      id: id,
      type: type,
      title: title,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
