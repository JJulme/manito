import 'package:manito/features_new/posts/domain/entities/post_entity.dart';

abstract class PostsRepository {
  Future<List<PostEntity>> getPosts(String languageCode);
  Future<PostEntity> getPost(String postId);
  Future<List<CommentEntity>> getComments(String missionId);
  Future<void> addComment(String missionId, String comment);
}
