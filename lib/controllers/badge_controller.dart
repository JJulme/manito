import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BadgeController extends GetxController {
  // final PostController _postController = Get.find<PostController>();
  final _supabase = Supabase.instance.client;
  var friendRequestBadge = false.obs;
  // var postBadge = <String, RxBool>{}.obs;
  // var allPostBadge = false.obs;
  // var commentBadge = <String, bool>{}.obs;
  var missionBadge = false.obs;
  var missonProposeBadge = false.obs;

  // 뱃지 설정
  // 뱃지 구독 채널
  // RealtimeChannel? _channel;
  // UI 사용 개별 Rx 변수들
  var badgeFriendRequest = 0.obs;
  var badgeMissionPropose = 0.obs;
  var badgeMission = 0.obs;
  // 내부 사용 반응형 Map
  final Map<String, RxInt> _badgeMap = {
    'friend_request': 0.obs,
    'mission_propose': 0.obs,
    'mission_accept': 0.obs,
    'mission_complete': 0.obs,
  };

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
    // for (var post in data) {
    //   postBadge[post['id']] =
    //       (prefs.getBool('post_${post['id']}') ?? false).obs;
    // }
    updateHasAnyPost();
  }

  /// 모든 값이 false 인지 값 업데이트
  void updateHasAnyPost() {
    // allPostBadge.value = postBadge.values.any((rxBool) => rxBool.value);
  }

  /// 친구 요청 뱃지 상태 지우기
  void clearFriendRequest() async {
    friendRequestBadge.value = false;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('friend_request');
    badgeFriendRequest.value = 0;
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
      // postBadge[missionId] = false.obs;
      updateHasAnyPost();
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('post_$missionId');
    } catch (e) {
      debugPrint('clearComment Error: $e');
    }
  }

  /// 각 포스트 상태 지우기
  void clearChat(String missionId) async {
    try {
      // postBadge[missionId] = false.obs;
      updateHasAnyPost();
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('post_$missionId');
    } catch (e) {
      debugPrint('clearComment Error: $e');
    }
  }

  // 뱃지 서버 관리로 리뉴얼
  /// 뱃지 목록 가져오기
  Future<void> fetchExistingBadges() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('badges')
          .select('badge_type, count')
          .eq('user_id', userId);

      // 초기값으로 리셋
      _badgeMap.forEach((key, value) => value.value = 0);

      // 데이터 삽입
      for (final item in data) {
        final badgeType = item['badge_type'];
        final count = item['count'] ?? 0;

        if (badgeType != null && _badgeMap.containsKey(badgeType)) {
          _badgeMap[badgeType]?.value = count;
        }
      }

      // 개별 Rx 업데이트
      _updateIndividualCounters();
    } catch (e) {
      debugPrint('fetchExistingBadges Error: $e');
    }
  }

  // 개별 카운터 업데이트
  void _updateIndividualCounters() {
    badgeFriendRequest.value = _badgeMap['friend_request']?.value ?? 0;
    badgeMissionPropose.value = _badgeMap['mission_propose']?.value ?? 0;
    badgeMission.value =
        (_badgeMap['mission_accept']?.value ?? 0) +
        (_badgeMap['mission_complete']?.value ?? 0);
  }

  // 해당 뱃지 초기화
  Future<void> resetBadgeCount(String badgeType) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase
          .from('badges')
          .update({'count': 0})
          .eq('user_id', userId)
          .eq('badge_type', badgeType);
      if (_badgeMap.containsKey(badgeType)) {
        _badgeMap[badgeType]?.value = 0;
        _updateIndividualCounters();
      }
    } catch (e) {
      debugPrint('resetBadgeCount: $e');
    }
  }

  // /// 실시간 뱃지 구독
  // void subscribToBadges() {
  //   final userId = _supabase.auth.currentUser!.id;
  //   _channel =
  //       _supabase
  //           .channel('badges: $userId')
  //           .onPostgresChanges(
  //             event: PostgresChangeEvent.all,
  //             schema: 'public',
  //             table: 'badges',
  //             filter: PostgresChangeFilter(
  //               type: PostgresChangeFilterType.eq,
  //               column: 'user_id',
  //               value: userId,
  //             ),
  //             callback: _badgeEventHandler,
  //           )
  //           .subscribe();
  //   debugPrint('뱃지 실시간 구독: $userId');
  // }

  // /// 채널 이벤트 핸들러 - 미완성
  // void _badgeEventHandler(payload) {
  //   debugPrint('Real-time event received: ${payload.toString()}');
  //   // 인서트
  //   if (payload.eventType == PostgresChangeEvent.insert) {
  //   }
  //   // 업데이트
  //   else if (payload.eventType == PostgresChangeEvent.update) {
  //   }
  //   // 삭제
  //   else if (payload.eventType == PostgresChangeEvent.delete) {}
  // }
}
