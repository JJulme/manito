class CommentReadLogModel {
  final int logId;
  final int commentId;
  final String userId;
  final bool isRead;
  final DateTime? readAt;

  const CommentReadLogModel({
    required this.logId,
    required this.commentId,
    required this.userId,
    required this.isRead,
    this.readAt,
  });

  factory CommentReadLogModel.fromJson(Map<String, dynamic> json) {
    return CommentReadLogModel(
      logId: json['log_id'] as int,
      commentId: json['comment_id'] as int,
      userId: json['user_id'] as String,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'log_id': logId,
      'comment_id': commentId,
      'user_id': userId,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
    };
  }
}
