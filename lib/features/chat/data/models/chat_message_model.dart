import 'package:manito/core/models/user_model.dart';

enum ChatMessageType {
  text('TEXT'),
  image('IMAGE'),
  emoticon('EMOTICON'),
  system('SYSTEM');

  final String value;
  const ChatMessageType(this.value);

  static ChatMessageType fromString(String val) {
    return ChatMessageType.values.firstWhere(
      (e) => e.value == val.toUpperCase(),
      orElse: () => ChatMessageType.text,
    );
  }
}

class ChatMessageModel {
  final String id;
  final String roomId;
  final String? senderId;
  final ChatMessageType type;
  final String? content;
  final List<String> imageUrls;
  final String? emoticonId;
  final DateTime createdAt;
  final UserModel? sender;
  final int unreadCount;

  const ChatMessageModel({
    required this.id,
    required this.roomId,
    this.senderId,
    required this.type,
    this.content,
    this.imageUrls = const [],
    this.emoticonId,
    required this.createdAt,
    this.sender,
    this.unreadCount = 0,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, {int unreadCount = 0}) {
    List<String> parsedImageUrls = [];
    if (json['image_urls'] is List) {
      parsedImageUrls = (json['image_urls'] as List).map((e) => e.toString()).toList();
    }

    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      roomId: json['room_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString(),
      type: ChatMessageType.fromString(json['type']?.toString() ?? 'TEXT'),
      content: json['content'] as String?,
      imageUrls: parsedImageUrls,
      emoticonId: json['emoticon_id'] as String?,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      sender: json['users'] is Map<String, dynamic>
          ? UserModel.fromJson(json['users'] as Map<String, dynamic>)
          : (json['sender'] is Map<String, dynamic>
              ? UserModel.fromJson(json['sender'] as Map<String, dynamic>)
              : null),
      unreadCount: unreadCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'type': type.value,
      'content': content,
      'image_urls': imageUrls,
      'emoticon_id': emoticonId,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  ChatMessageModel copyWith({
    UserModel? sender,
    int? unreadCount,
  }) {
    return ChatMessageModel(
      id: id,
      roomId: roomId,
      senderId: senderId,
      type: type,
      content: content,
      imageUrls: imageUrls,
      emoticonId: emoticonId,
      createdAt: createdAt,
      sender: sender ?? this.sender,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
