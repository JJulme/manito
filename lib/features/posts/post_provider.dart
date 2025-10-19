import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features/posts/post.dart';
import 'package:manito/features/posts/post_service.dart';

// Provider
final postsServiceProvider = Provider<PostsService>((ref) {
  final supabase = ref.read(supabaseProvider);
  return PostsService(supabase);
});

final postsProvider = StateNotifierProvider<PostsNotifier, PostsState>((ref) {
  final service = ref.watch(postsServiceProvider);
  return PostsNotifier(ref, service);
});

// 각 포스트 마다 독립적인 프로바이더 생성
StateNotifierProvider<PostDetailNotifier, PostDetailState>
createPostDetailProvider(Post originalPost) {
  return StateNotifierProvider<PostDetailNotifier, PostDetailState>((ref) {
    final service = ref.watch(postsServiceProvider);
    final notifier = PostDetailNotifier(ref, service, originalPost);
    // ref.onDispose(() {});
    Future.microtask(() => notifier.init());
    return notifier;
  });
}

// Notifier
class PostsNotifier extends StateNotifier<PostsState> {
  final Ref _ref;
  final PostsService _service;
  PostsNotifier(this._ref, this._service) : super(const PostsState.initial());

  // 게시물 목록 가져오기
  Future<void> fetchPosts() async {
    try {
      state = state.copyWith(isLoading: true);

      final languageCode = _ref.read(languageCodeProvider);
      final posts = await _service.fetchPosts(languageCode);

      state = state.copyWith(postList: posts, isLoading: false, error: null);
    } catch (e) {
      debugPrint('PostNotifier.fetchPosts Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // 친구와 게시물
  List<Post> getPostsWithFriend(String friendId) {
    return state.postList
        .where(
          (post) => post.creatorId == friendId || post.manitoId == friendId,
        )
        .toList();
  }
}

class PostDetailNotifier extends StateNotifier<PostDetailState> {
  final Ref _ref;
  final PostsService _service;
  final Post originalPost;
  PostDetailNotifier(this._ref, this._service, this.originalPost)
    : super(const PostDetailState.initial());

  Future<void> init() async {
    try {
      state = state.copyWith(isLoading: true);
      await Future.wait([getPostDetail(), fetchComments()]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('PostDetailNotifier.init Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // 단일 게시물 가져오기
  Future<void> getPostDetail() async {
    try {
      final detailPost = await _service.getPost(originalPost.id!);
      final mergedPost = detailPost.copyWith(
        id: originalPost.id,
        completeAt: originalPost.completeAt,
        contentType: originalPost.contentType,
        content: originalPost.content,
      );

      state = state.copyWith(postDetail: mergedPost);
    } catch (e) {
      debugPrint('PostDetailNotifier.getPostDetail Error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  // 댓글 목록 가져오기
  Future<void> fetchComments() async {
    try {
      state = state.copyWith(commentLoading: true);
      final comments = await _service.fetchComments(originalPost.id!);
      state = state.copyWith(commentList: comments, commentLoading: false);
    } catch (e) {
      debugPrint('PostDetailNotifier.fetchComments Error: $e');
      state = state.copyWith(commentLoading: false, error: e.toString());
    }
  }

  // 댓글 삽압
  Future<void> insertComment(String comment) async {
    try {
      final currentUser = _ref.read(currentUserProvider);
      await _service.insertComment(originalPost.id!, currentUser!.id, comment);
      await fetchComments();
    } catch (e) {
      debugPrint('PostDetailNotifier.insertComment Error: $e');
      state = state.copyWith(error: e.toString());
    }
  }
}
