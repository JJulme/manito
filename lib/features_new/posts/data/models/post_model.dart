import 'package:manito/features_new/posts/domain/entities/post_entity.dart';

class PostModel extends PostEntity {
  PostModel({
    super.id,
    super.creatorId,
    super.manitoId,
    super.description,
    super.imageUrlList,
    super.createdAt,
    super.completeAt,
    super.contentType,
    super.content,
    super.guess,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? '',
      creatorId: json['creator_id'] ?? '',
      manitoId: json['manito_id'] ?? '',
      description: json['description'] ?? '',
      imageUrlList: json['image_url_list'] != null
          ? List<String>.from(json['image_url_list'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : null,
      completeAt: json['complete_at'] != null
          ? DateTime.parse(json['complete_at']).toLocal()
          : null,
      contentType: json['content_type'] ?? '',
      content: json['content'] ?? '',
      guess: json['guess'] ?? '',
    );
  }
}

class CommentModel extends CommentEntity {
  CommentModel({
    required super.id,
    required super.missionId,
    required super.userId,
    required super.comment,
    required super.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      missionId: json['mission_id'] as String,
      userId: json['user_id'] as String,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
