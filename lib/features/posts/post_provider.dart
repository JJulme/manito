import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features/error/error_provider.dart';
import 'package:manito/features/posts/post.dart';
import 'package:manito/features/posts/post_service.dart';

// ========== Service Provider ==========
final postsServiceProvider = Provider<PostsService>((ref) {
  final supabase = ref.read(supabaseProvider);
  return PostsService(supabase);
});

// ========== Notifier Provider ==========
final postsProvider = AsyncNotifierProvider<PostsNotifier, PostsState>(
  PostsNotifier.new,
);

final postDetailProvider =
    AsyncNotifierProvider.family<PostDetailNotifier, PostDetailState, String>(
      PostDetailNotifier.new,
    );
final postCommentProvider =
    AsyncNotifierProvider.family<PostCommentNotifier, PostCommentState, String>(
      PostCommentNotifier.new,
    );

// ========== Notifier ==========
class PostsNotifier extends AsyncNotifier<PostsState> {
  @override
  FutureOr<PostsState> build() async {
    try {
      final languageCode = ref.read(languageCodeProvider);
      final service = ref.read(postsServiceProvider);
      final posts = await service.fetchPosts(languageCode);
      return PostsState(postList: posts);
    } catch (e) {
      ref.read(errorProvider.notifier).setError('PostsNotifier Error: $e');
      return PostsState();
    }
  }

  Post getPostDetail(String postId) {
    final currentState = state.value;
    if (currentState == null) return Post();
    return currentState.postList.where((p) => p.id == postId).single;
  }

  // 친구와의 게시물
  List<Post> getPostsWithFriend(String friendId) {
    final currentState = state.value;
    if (currentState == null) return [];
    return currentState.postList.where((p) => p.creatorId == friendId).toList();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

class PostDetailNotifier extends FamilyAsyncNotifier<PostDetailState, String> {
  @override
  FutureOr<PostDetailState> build(String postId) async {
    try {
      final service = ref.read(postsServiceProvider);
      final originPost = ref.read(postsProvider.notifier).getPostDetail(postId);
      final detailPost = await service.getPost(postId);
      final mergedPost = detailPost.copyWith(
        id: postId,
        manitoId: originPost.manitoId,
        creatorId: originPost.creatorId,
        completeAt: originPost.completeAt,
        contentType: originPost.contentType,
        content: originPost.content,
      );
      return PostDetailState(postDetail: mergedPost);
    } catch (e) {
      ref.read(errorProvider.notifier).setError('PostDetailNotifier Error: $e');
      return PostDetailState();
    }
  }
}

class PostCommentNotifier
    extends FamilyAsyncNotifier<PostCommentState, String> {
  @override
  FutureOr<PostCommentState> build(String postId) async {
    try {
      final service = ref.read(postsServiceProvider);
      final comments = await service.fetchComments(postId);
      return PostCommentState(commentList: comments);
    } catch (e) {
      ref
          .read(errorProvider.notifier)
          .setError('PostCommentNotifier Error: $e');
      return PostCommentState();
    }
  }

  // 댓글 삽입
  Future<void> insertComment(String postId, String comment) async {
    try {
      final service = ref.read(postsServiceProvider);
      await service.insertComment(postId, comment);
      refresh();
    } catch (e) {
      ref.read(errorProvider.notifier).setError('insertComment Error: $e');
    }
  }

  // 새로고침
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
