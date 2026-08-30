import 'user_model.dart';

class CommentModel {
  final int commentId;
  final int recordId;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final UserModel? author;

  const CommentModel({
    required this.commentId,
    required this.recordId,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.author,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: (json['comment_id'] as num?)?.toInt() ?? 0,
      recordId: (json['record_id'] as num?)?.toInt() ?? 0,
      userId: json['user_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      author: json['author'] is Map<String, dynamic>
          ? UserModel.fromJson(json['author'] as Map<String, dynamic>)
          : (json['user'] is Map<String, dynamic>
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
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
