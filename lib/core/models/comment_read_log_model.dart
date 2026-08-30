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
      logId: (json['log_id'] as num?)?.toInt() ?? 0,
      commentId: (json['comment_id'] as num?)?.toInt() ?? 0,
      userId: json['user_id']?.toString() ?? '',
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString())?.toLocal() : null,
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
