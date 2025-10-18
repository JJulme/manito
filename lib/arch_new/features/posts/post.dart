// ========== Models ==========
/// 게시물 모델
///
/// 이 클래스는 애플리케이션 내의 단일 게시물 데이터를 나타냅니다.
/// 게시물은 다양한 화면에서 사용될 수 있으므로, 모든 필드는 null을 허용합니다.
class Post {
  /// 게시물의 고유 식별자 (ID).
  /// 데이터베이스에서 자동으로 생성되며, 게시물 조회에 사용됩니다.
  final String? id;

  /// 미션을 생성한 사용자의 ID.
  /// 미션 생정자를 식별하는 데 사용됩니다.
  final String? creatorId;

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

  /// 마니또 미션의 마감 기한 유형 ('하루', '한주').
  final String? contentType;

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
    this.creatorId,
    this.manitoId,
    this.description,
    this.imageUrlList,
    this.createdAt,
    this.completeAt,
    this.contentType,
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
      creatorId: json['creator_id'] ?? '',
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
      contentType: json['content_type'] ?? '',
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
    String? contentType,
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
      contentType: contentType ?? this.contentType,
      content: content ?? this.content,
      guess: guess ?? this.guess,
    );
  }
}

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
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}

// ========== States ==========
class PostsState {
  final List<Post> postList;
  final bool isLoading;
  final String? error;

  const PostsState({
    required this.postList,
    required this.isLoading,
    this.error,
  });

  const PostsState.initial()
    : isLoading = false,
      postList = const [],
      error = null;

  const PostsState.loading()
    : isLoading = true,
      postList = const [],
      error = null;

  PostsState copyWith({List<Post>? postList, bool? isLoading, String? error}) {
    return PostsState(
      postList: postList ?? this.postList,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  int creatorPostCount(String userId) {
    return postList.where((post) => post.creatorId == userId).length;
  }

  int manitoPostCount(String userId) {
    return postList.where((post) => post.manitoId == userId).length;
  }
}

class PostDetailState {
  final Post? postDetail;
  final List<Comment> commentList;
  final bool isLoading;
  final bool commentLoading;
  final String? error;

  const PostDetailState({
    this.postDetail,
    required this.commentList,
    required this.isLoading,
    required this.commentLoading,
    this.error,
  });

  const PostDetailState.initial()
    : postDetail = null,
      commentList = const [],
      isLoading = false,
      commentLoading = false,
      error = null;

  PostDetailState copyWith({
    Post? postDetail,
    List<Comment>? commentList,
    bool? isLoading,
    bool? commentLoading,
    String? error,
  }) {
    return PostDetailState(
      postDetail: postDetail ?? this.postDetail,
      commentList: commentList ?? this.commentList,
      isLoading: isLoading ?? this.isLoading,
      commentLoading: commentLoading ?? this.commentLoading,
      error: error ?? this.error,
    );
  }
}
