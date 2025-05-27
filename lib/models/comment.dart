/// 댓글 모델
///
/// 게시물에 달린 댓글의 상세 정보를 나타냅니다.
/// 댓글의 고유 ID, 관련 미션 ID, 작성자 ID, 댓글 내용,
/// 그리고 작성 시간을 포함하는 필수 필드들로 구성됩니다.
class Comment {
  /// 댓글의 고유 식별자 (ID).
  /// 이 필드는 필수입니다.
  final String id;

  /// 댓글이 속한 미션의 고유 식별자 (ID).
  /// 어떤 미션 게시물에 달린 댓글인지 식별하는 데 사용됩니다. 이 필드는 필수입니다.
  final String missionId;

  /// 댓글을 작성한 사용자의 고유 식별자 (ID).
  /// 댓글의 작성자를 식별하는 데 사용됩니다. 이 필드는 필수입니다.
  final String userId;

  /// 댓글의 실제 내용.
  /// 사용자가 작성한 텍스트를 포함합니다. 이 필드는 필수입니다.
  final String comment;

  /// 댓글이 생성된 UTC 시간.
  /// [DateTime] 객체로 저장되며, 이 필드는 필수입니다.
  final DateTime createdAt;

  /// 새로운 [Comment] 인스턴스를 생성합니다.
  ///
  /// 모든 매개변수는 필수입니다.
  Comment({
    required this.id,
    required this.missionId,
    required this.userId,
    required this.comment,
    required this.createdAt,
  });

  /// JSON [Map]으로부터 [Comment] 인스턴스를 생성하는 팩토리 생성자.
  ///
  /// [json]: API 응답으로 받은 JSON 데이터 맵입니다.
  /// 모든 필드는 JSON 데이터의 최상위 레벨에서 직접 파싱됩니다.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      missionId: json['mission_id'] as String,
      userId: json['user_id'] as String,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
