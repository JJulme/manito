import 'package:timeago/timeago.dart' as timeago;

class Comment {
  final String id;
  final String missionId;
  final String userId;
  final String comment;
  final String createdAt;

  Comment({
    required this.id,
    required this.missionId,
    required this.userId,
    required this.comment,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // final DateFormat formatter = DateFormat('yy-MM-dd HH:mm:ss');
    return Comment(
      id: json['id'],
      missionId: json['mission_id'],
      userId: json['user_id'],
      comment: json['comment'],
      createdAt:
          timeago.format(DateTime.parse(json['created_at']), locale: 'ko'),
    );
  }
}
