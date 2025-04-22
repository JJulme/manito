import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BadgeController extends GetxController {
  // final PostController _postController = Get.find<PostController>();
  final _supabase = Supabase.instance.client;
  var friendRequestBadge = false.obs;
  var postBadge = <String, RxBool>{}.obs;
  var allPostBadge = false.obs;
  // var commentBadge = <String, bool>{}.obs;
  var missionBadge = false.obs;
  var missonProposeBadge = false.obs;

  /// 저장된 뱃지 상태 정보를 가져옴 - postBadge가 바뀌는 모든 곳에 실행
  Future<void> loadBadgeState() async {
    final prefs = await SharedPreferences.getInstance();
    // 저장소 새로고침
    await prefs.reload();
    // 친구신청
    friendRequestBadge.value = prefs.getBool('friend_request') ?? false;
    // 내가 만든 미션
    missionBadge.value = prefs.getBool('update_mission') ?? false;
    // 미션 제의
    missonProposeBadge.value = prefs.getBool('mission_propose') ?? false;

    // 미션 목록 가져오기
    String userId = _supabase.auth.currentUser!.id;
    final data = await _supabase
        .from('post_view')
        .select('id')
        .or('creator_id.eq.$userId, manito_id.eq.$userId')
        .order('created_at', ascending: false);

    // 새로운 게시물, 댓글
    for (var post in data) {
      postBadge[post['id']] =
          (prefs.getBool('post_${post['id']}') ?? false).obs;
    }
    updateHasAnyPost();
  }

  /// 모든 값이 false 인지 값 업데이트
  void updateHasAnyPost() {
    allPostBadge.value = postBadge.values.any((rxBool) => rxBool.value);
  }

  /// 친구 요청 뱃지 상태 지우기
  void clearFriendRequest() async {
    friendRequestBadge.value = false;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('friend_request');
  }

  /// 미션 뱃지 상태 지우기
  void clearMission() async {
    missionBadge.value = false;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('update_mission');
  }

  /// 마니또 뱃지 상태 지우기
  void clearMissionPropose() async {
    missonProposeBadge.value = false;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('mission_propose');
  }

  /// 각 포스트 상태 지우기
  void clearComment(String missionId) async {
    try {
      postBadge[missionId] = false.obs;
      updateHasAnyPost();
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('post_$missionId');
    } catch (e) {
      debugPrint('clearComment Error: $e');
    }
  }
}
