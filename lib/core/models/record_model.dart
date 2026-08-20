import 'user_model.dart';
import 'comment_model.dart';

enum RecordType {
  missionPerform('MISSION_PERFORM'),
  suspectGuess('SUSPECT_GUESS');

  final String value;
  const RecordType(this.value);

  static RecordType fromString(String val) {
    return RecordType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => RecordType.missionPerform,
    );
  }
}

enum BlockType {
  text('text'),
  image('image');

  final String value;
  const BlockType(this.value);

  static BlockType fromString(String val) {
    return BlockType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => BlockType.text,
    );
  }
}

class RecordBlock {
  final BlockType type;
  final String value; // text string or image URL

  const RecordBlock({
    required this.type,
    required this.value,
  });

  factory RecordBlock.fromJson(Map<String, dynamic> json) {
    return RecordBlock(
      type: BlockType.fromString(json['type'] as String? ?? 'text'),
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'value': value,
    };
  }
}

class RecordModel {
  final int recordId;
  final String roomId;
  final String userId;
  final RecordType recordType;
  final String? suspectUserId;
  final List<RecordBlock> content;
  final bool isDeleted;
  final DateTime createdAt;
  final UserModel? author;
  final UserModel? suspectUser;
  final List<CommentModel>? comments;

  const RecordModel({
    required this.recordId,
    required this.roomId,
    required this.userId,
    required this.recordType,
    this.suspectUserId,
    required this.content,
    required this.isDeleted,
    required this.createdAt,
    this.author,
    this.suspectUser,
    this.comments,
  });

  factory RecordModel.fromJson(Map<String, dynamic> json) {
    List<RecordBlock> blocks = [];
    if (json['content'] is List) {
      blocks = (json['content'] as List)
          .map((e) => RecordBlock.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['content'] is Map) {
      blocks = [RecordBlock.fromJson(json['content'] as Map<String, dynamic>)];
    }

    return RecordModel(
      recordId: json['record_id'] as int,
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      recordType: RecordType.fromString(json['record_type'] as String),
      suspectUserId: json['suspect_user_id'] as String?,
      content: blocks,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      author: json['author'] != null
          ? UserModel.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      suspectUser: json['suspect_user'] != null
          ? UserModel.fromJson(json['suspect_user'] as Map<String, dynamic>)
          : null,
      comments: json['comments'] != null
          ? (json['comments'] as List)
              .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'record_id': recordId,
      'room_id': roomId,
      'user_id': userId,
      'record_type': recordType.value,
      'suspect_user_id': suspectUserId,
      'content': content.map((b) => b.toJson()).toList(),
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
