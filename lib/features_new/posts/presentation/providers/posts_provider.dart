import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/error/error_provider.dart';
import 'package:manito/features_new/posts/domain/entities/post_entity.dart';
import 'package:manito/features_new/posts/domain/repositories/repository_provider.dart';

// ========== Notifier Providers ==========
final postsProvider =
    AsyncNotifierProvider<PostsNotifier, List<PostEntity>>(() {
  return PostsNotifier();
});

final postDetailProvider =
    AsyncNotifierProvider.family<PostDetailNotifier, PostEntity?, String>(() {
  return PostDetailNotifier();
});

final postCommentProvider =
    AsyncNotifierProvider.family<PostCommentNotifier, List<CommentEntity>, String>(() {
  return PostCommentNotifier();
});

// ========== Notifiers ==========
class PostsNotifier extends AsyncNotifier<List<PostEntity>> {
  @override
  FutureOr<List<PostEntity>> build() async {
    try {
      final languageCode = ref.watch(languageCodeProvider);
      final repository = ref.watch(postsRepositoryProvider);
      return repository.getPosts(languageCode);
    } catch (e) {
      ref.read(errorProvider.notifier).setError('PostsNotifier Error: $e');
      return [];
    }
  }

  PostEntity? getPostDetail(String postId) {
    final currentState = state.value;
    if (currentState == null) return null;
    return currentState.where((p) => p.id == postId).firstOrNull;
  }

  // 친구와의 게시물
  List<PostEntity> getPostsWithFriend(String friendId) {
    final currentState = state.value;
    if (currentState == null) return [];
    return currentState.where((p) => p.creatorId == friendId).toList();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

class PostDetailNotifier extends FamilyAsyncNotifier<PostEntity?, String> {
  @override
  FutureOr<PostEntity?> build(String postId) async {
    try {
      final repository = ref.watch(postsRepositoryProvider);
      final originPost = ref.read(postsProvider.notifier).getPostDetail(postId);
      final detailPost = await repository.getPost(postId);
      final mergedPost = detailPost.copyWith(
        id: postId,
        manitoId: originPost?.manitoId,
        creatorId: originPost?.creatorId,
        completeAt: originPost?.completeAt,
        contentType: originPost?.contentType,
        content: originPost?.content,
      );
      return mergedPost;
    } catch (e) {
      ref.read(errorProvider.notifier).setError('PostDetailNotifier Error: $e');
      return null;
    }
  }
}

class PostCommentNotifier extends FamilyAsyncNotifier<List<CommentEntity>, String> {
  @override
  FutureOr<List<CommentEntity>> build(String postId) async {
    try {
      final repository = ref.watch(postsRepositoryProvider);
      return repository.getComments(postId);
    } catch (e) {
      ref.read(errorProvider.notifier).setError('PostCommentNotifier Error: $e');
      return [];
    }
  }

  // 댓글 삽입
  Future<void> insertComment(String postId, String comment) async {
    try {
      final repository = ref.read(postsRepositoryProvider);
      await repository.addComment(postId, comment);
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
