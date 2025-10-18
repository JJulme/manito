import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:manito/models/comment.dart';
import 'package:manito/models/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostController extends GetxController {
  final _supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var inCompletePostList = [].obs;
  var postList = <Post>[].obs; // 게시물 목록

  /// 포스트들을 가져오는 함수
  Future<void> fetchPosts() async {
    isLoading.value = true;
    String userId = _supabase.auth.currentUser!.id;
    final String currentLanguageCode =
        EasyLocalization.of(Get.context!)!.locale.languageCode;
    try {
      final data = await _supabase
          .from('missions')
          .select('''id, 
            manito_id, 
            creator_id, 
            content_type, 
            content_library:content($currentLanguageCode), 
            complete_at
            ''')
          .or('creator_id.eq.$userId, manito_id.eq.$userId')
          .not('guess', 'is', null)
          .order('complete_at', ascending: false);

      // content 빼오기
      List<Map<String, dynamic>> transformedData = [];
      for (var mission in data) {
        Map<String, dynamic> newMission = Map.from(mission);
        if (newMission['content_library'] is Map<String, dynamic>) {
          Map<String, dynamic> contentMap = newMission['content_library'];
          if (contentMap.isNotEmpty) {
            newMission['content'] = contentMap.values.first;
          } else {
            newMission['content'] = null;
          }
        }
        transformedData.add(newMission);
      }
      postList.value =
          transformedData.map((post) => Post.fromJson(post)).toList();
    } catch (e) {
      debugPrint('fetchPosts Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 사용자의 미션 생성자 수 반환
  int get creatorPostCount {
    String userId = _supabase.auth.currentUser!.id;
    return postList.where((post) => post.creatorId == userId).length;
  }

  /// 사용자의 미션 마니또 수 반환
  int get manitoPostCount {
    String userId = _supabase.auth.currentUser!.id;
    return postList.where((post) => post.manitoId == userId).length;
  }
}

class PostDetailController extends GetxController {
  final _supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var commentLoading = false.obs;
  late var manitoProfile;
  late var creatorProfile;
  late Post post; // deadlineType, content, createdAt
  var detailPost = Rx<Post?>(null);
  var commentList = <Comment>[].obs; // 댓글 목록
  // 텍스트 컨트롤러
  final TextEditingController commentController = TextEditingController();
  // 스크롤 컨트롤러
  final ScrollController commentScrollController = ScrollController();

  @override
  void onInit() async {
    super.onInit();
    post = Get.arguments[0];
    manitoProfile = Get.arguments[1];
    creatorProfile = Get.arguments[2];
    isLoading.value = true;
    await getPost();
    await fetchComment();
    isLoading.value = false;
  }

  /// 게시물 가져오기
  Future<void> getPost() async {
    try {
      final data =
          await _supabase
              .from('missions')
              .select('description, image_url_list, guess')
              .eq('id', post.id!)
              .single();
      detailPost.value = Post.fromJson(data);
      // 기존 썸네일 정보 덮어쓰기
      detailPost.value = detailPost.value?.copyWith(
        id: post.id,
        completeAt: post.completeAt,
        contentType: post.contentType,
        content: post.content,
      );
    } catch (e) {
      debugPrint('getPost Error: $e');
    }
  }

  /// 게시물의 댓글 가져오기
  Future<void> fetchComment() async {
    commentLoading.value = true;
    try {
      final data = await _supabase
          .from('comments')
          .select()
          .eq('mission_id', post.id!)
          .order('created_at', ascending: false);
      commentList.value =
          data.map((comment) => Comment.fromJson(comment)).toList();
    } catch (e) {
      debugPrint('fetchComment Error: $e');
    } finally {
      commentLoading.value = false;
    }
  }

  /// 댓글 보내기
  Future<void> insertComment() async {
    try {
      await _supabase.from('comments').insert({
        "mission_id": post.id,
        "user_id": _supabase.auth.currentUser!.id,
        "comment": commentController.text,
      });
      fetchComment();
    } catch (e) {
      debugPrint('insertComment Error: $e');
    }
  }
}

// 댓글 바텀 시트에서 사용됨
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
