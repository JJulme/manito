import 'user_model.dart';

class CommentModel {
  final int commentId;
  final int recordId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final UserModel? author;

  const CommentModel({
    required this.commentId,
    required this.recordId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.author,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: json['comment_id'] as int,
      recordId: json['record_id'] as int,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      author: json['author'] != null
          ? UserModel.fromJson(json['author'] as Map<String, dynamic>)
          : (json['user'] != null
              ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment_id': commentId,
      'record_id': recordId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
