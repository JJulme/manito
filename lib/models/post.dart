import 'package:timeago/timeago.dart' as timeago;

/// 게시물 모델
class Post {
  final String? id;
  final String? manitoId;
  final String? description;
  final List<String?>? imageUrlList;
  final String? createdAt;

  final String? creatorId;
  final String? deadlineType;
  final String? content;
  final String? guess;

  Post({
    this.id,
    this.manitoId,
    this.description,
    this.imageUrlList,
    this.createdAt,
    this.creatorId,
    this.deadlineType,
    this.content,
    this.guess,
  });

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
              ? timeago.format(DateTime.parse(json['created_at']), locale: 'ko')
              : '',
      creatorId: json['creator_id'] ?? '',
      deadlineType: json['deadline_type'] ?? '',
      content: json['content'] ?? '',
      guess: json['guess'] ?? '',
    );
  }

  // copyWith 메서드 추가
  Post copyWith({
    String? id,
    String? createdAt,
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
      creatorId: creatorId ?? this.creatorId,
      deadlineType: deadlineType ?? this.deadlineType,
      content: content ?? this.content,
      guess: guess ?? this.guess,
    );
  }
}
