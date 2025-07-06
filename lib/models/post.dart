/// 게시물 모델
///
/// 이 클래스는 애플리케이션 내의 단일 게시물 데이터를 나타냅니다.
/// 게시물은 다양한 화면에서 사용될 수 있으므로, 모든 필드는 null을 허용합니다.
class Post {
  /// 게시물의 고유 식별자 (ID).
  /// 데이터베이스에서 자동으로 생성되며, 게시물 조회에 사용됩니다.
  final String? id;

  /// 게시물과 연결된 마니또(manito) 사용자의 ID.
  /// 특정 마니또 정보를 가져오는데 사용됩니다.
  final String? manitoId;

  /// 마니또 사용자의 미션 수행 내용.
  /// 마니또 사용자가 작성한 게시물 텍스트입니다.
  final String? description;

  /// 게시물에 첨부된 이미지 URL들의 리스트.
  /// 이미지가 없는 경우 null이 될 수 있으며, 각 URL도 null일 수 있습니다.
  final List<String?>? imageUrlList;

  /// 미션이 생성된 UTC 시간.
  /// 'YYYY-MM-DDTHH:MM:SSZ' 형식의 문자열로 파싱됩니다.
  final DateTime? createdAt;

  /// 미션 생성자가 추측까지 완료된 UTC 시간.
  /// 완료되지 않은 경우 null입니다.
  final DateTime? completeAt;

  /// 미션을 생성한 사용자의 ID.
  /// 미션 생정자를 식별하는 데 사용됩니다.
  final String? creatorId;

  /// 마니또 미션의 마감 기한 유형 ('하루', '한주').
  final String? deadlineType;

  /// 마니또 사용자의 구체적인 미션 내용.
  /// 마니또 사용자가 랜덤으로 제시된 미션중에 선택한 내용입니다.
  final String? content;

  /// 미션 생성자가 마니또가 누군지 추측 내용.
  /// 미션 생성자가 어떤 친구가 어떤 미션을 수행했는지 추측하는 문자열.
  /// 추측이 이루지면 미션이 종료
  final String? guess;

  /// 새로운 [Post] 인스턴스를 생성합니다.
  ///
  /// 모든 필드는 선택 사항이며 null을 허용합니다.
  Post({
    this.id,
    this.manitoId,
    this.description,
    this.imageUrlList,
    this.createdAt,
    this.completeAt,
    this.creatorId,
    this.deadlineType,
    this.content,
    this.guess,
  });

  /// JSON [Map]으로부터 [Post] 인스턴스를 생성하는 팩토리 생성자.
  ///
  /// JSON 데이터가 없는 경우 빈 문자열(`''`) 또는 `null`로 대체됩니다.
  /// `createdAt`과 `completeAt`은 [DateTime] 객체로 파싱됩니다.
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      manitoId: json['manito_id'] ?? '',
      description: json['description'] ?? '',
      imageUrlList:
          json['image_url_list'] != null
              ? List<String>.from(json['image_url_list'])
              : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at']).toLocal()
              : null,
      completeAt:
          json['complete_at'] != null
              ? DateTime.parse(json['complete_at']).toLocal()
              : null,
      creatorId: json['creator_id'] ?? '',
      deadlineType: json['deadline_type'] ?? '',
      content: json['content'] ?? '',
      guess: json['guess'] ?? '',
    );
  }

  /// 현재 [Post] 인스턴스의 필드를 복사하여 새로운 [Post] 인스턴스를 생성합니다.
  ///
  /// 특정 필드를 변경하면서 나머지 필드는 그대로 유지할 때 유용합니다.
  Post copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? completeAt,
    String? description,
    List<String?>? imageUrlList,
    String? manitoId,
    String? creatorId,
    String? deadlineType,
    String? content,
    String? guess,
  }) {
    return Post(
      id: id ?? this.id,
      manitoId: manitoId ?? this.manitoId,
      description: description ?? this.description,
      imageUrlList: imageUrlList ?? this.imageUrlList,
      createdAt: createdAt ?? this.createdAt,
      completeAt: completeAt ?? this.completeAt,
      creatorId: creatorId ?? this.creatorId,
      deadlineType: deadlineType ?? this.deadlineType,
      content: content ?? this.content,
      guess: guess ?? this.guess,
    );
  }
}
