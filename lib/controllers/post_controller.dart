import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:manito/models/comment.dart';
import 'package:manito/models/post.dart';
import 'package:manito/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostController extends GetxController {
  final _supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var inCompletePostList = [].obs;
  var postList = <Post>[].obs; // 게시물 목록

  @override
  void onInit() async {
    super.onInit();
    isLoading.value = true;
    await fetchPosts();
    // await fetchIncompletePost();
    isLoading.value = false;
  }

  // /// 추측이 완료 안된 게시물 가져오기 - 수정 필요
  // Future<void> fetchIncompletePost() async {
  //   inCompletePostList.clear();
  //   try {
  //     // final List<dynamic> data = await _supabase.rpc(
  //     //   'fetch_incomplete_missions',
  //     //   params: {'user_id': _supabase.auth.currentUser!.id},
  //     // );
  //     final List<dynamic> data = await _supabase
  //         .from('missions')
  //         .select('id, creator_id')
  //         .eq('manito_id', _supabase.auth.currentUser!.id)
  //         .isFilter('guess', null)
  //         .order('created_at', ascending: false);
  //     print(data);
  //     if (data.isNotEmpty) {
  //       for (var mission in data) {
  //         inCompletePostList.add(mission['creator_id']);
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint('fetchIncompletePost Error: $e');
  //   }
  // }

  /// 포스트들을 가져오는 함수
  Future<void> fetchPosts() async {
    // isLoading.value = true;
    String userId = _supabase.auth.currentUser!.id;
    try {
      // final data = await _supabase
      //     .from('post_view')
      //     .select(
      //       'id, manito_id, creator_id, deadline_type, content, created_at',
      //     )
      //     .or('creator_id.eq.$userId, manito_id.eq.$userId')
      //     .order('created_at', ascending: false);
      final data = await _supabase
          .from('missions')
          .select(
            'id, manito_id, creator_id, deadline_type, content, created_at',
          )
          .or('creator_id.eq.$userId, manito_id.eq.$userId')
          .not('guess', 'is', null)
          .order('created_at', ascending: false);
      postList.value = data.map((post) => Post.fromJson(post)).toList();
    } catch (e) {
      debugPrint('fetchPosts Error: $e');
    } finally {
      // isLoading.value = false;
    }
  }
}

class PostDetailController extends GetxController {
  final _supabase = Supabase.instance.client;
  var isLoading = false.obs;
  late UserProfile manitoProfile;
  late UserProfile creatorProfile;
  late Post post; // deadlineType, content, createdAt
  var detailPost = Rx<Post?>(null);
  var commentList = <Comment>[].obs; // 댓글 목록
  final TextEditingController commentController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    post = Get.arguments[0];
    manitoProfile = Get.arguments[1];
    creatorProfile = Get.arguments[2];
    getPost(post.id!);
  }

  /// 게시물 가져오기
  Future<void> getPost(String id) async {
    isLoading.value = true;
    try {
      final data =
          await _supabase
              .from('missions')
              .select('description, image_url_list, guess')
              .eq('id', id)
              .single();
      detailPost.value = Post.fromJson(data);
      // 기존 썸네일 정보 덮어쓰기
      detailPost.value = detailPost.value?.copyWith(
        id: post.id,
        createdAt: post.createdAt,
        deadlineType: post.deadlineType,
        content: post.content,
      );
    } catch (e) {
      debugPrint('getPost Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // /// 게시물의 댓글 가져오기
  // Future<void> fetchComment() async {
  //   commentLoading.value = true;
  //   try {
  //     final data =
  //         await _supabase.from('comments').select().eq('mission_id', post.id!);
  //     commentList.value =
  //         data.map((comment) => Comment.fromJson(comment)).toList();
  //   } catch (e) {
  //     debugPrint('fetchComment Error: $e');
  //   } finally {
  //     commentLoading.value = false;
  //   }
  // }

  // /// 댓글 보내기
  // Future<void> insertComment() async {
  //   try {
  //     final data = {
  //       "mission_id": post.id,
  //       "user_id": _supabase.auth.currentUser!.id,
  //       "comment": commentController.text,
  //     };
  //     await _supabase.from('comments').insert(data);
  //     fetchComment();
  //   } catch (e) {
  //     debugPrint('insertComment Error: $e');
  //   }
  // }
}

class CommentController extends GetxController {
  // 초기값 받아오기
  final String missionId;
  CommentController(this.missionId);

  final _supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var commentList = <Comment>[].obs; // 댓글 목록
  final TextEditingController commentController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchComment();
  }

  /// 게시물의 댓글 가져오기
  Future<void> fetchComment() async {
    isLoading.value = true;
    try {
      final data = await _supabase
          .from('comments')
          .select()
          .eq('mission_id', missionId)
          .order('created_at', ascending: false);
      commentList.value =
          data.map((comment) => Comment.fromJson(comment)).toList();
    } catch (e) {
      debugPrint('fetchComment Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 댓글 보내기
  Future<void> insertComment() async {
    try {
      await _supabase.from('comments').insert({
        "mission_id": missionId,
        "user_id": _supabase.auth.currentUser!.id,
        "comment": commentController.text,
      });
      fetchComment();
    } catch (e) {
      debugPrint('insertComment Error: $e');
    }
  }
}
