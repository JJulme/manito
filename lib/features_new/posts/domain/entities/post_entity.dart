class PostEntity {
  final String? id;
  final String? creatorId;
  final String? manitoId;
  final String? description;
  final List<String?>? imageUrlList;
  final DateTime? createdAt;
  final DateTime? completeAt;
  final String? contentType;
  final String? content;
  final String? guess;

  PostEntity({
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

  PostEntity copyWith({
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
    return PostEntity(
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

class CommentEntity {
  final String id;
  final String missionId;
  final String userId;
  final String comment;
  final DateTime createdAt;

  CommentEntity({
    required this.id,
    required this.missionId,
    required this.userId,
    required this.comment,
    required this.createdAt,
  });
}
