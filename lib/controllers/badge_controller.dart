import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BadgeController extends GetxController {
  // final PostController _postController = Get.find<PostController>();
  final _supabase = Supabase.instance.client;
  // 내부 사용 반응형 Map
  final Map<String, RxInt> badgeMap = {
    'friend_request': 0.obs, // 친구 신청
    'mission_propose': 0.obs, // 마니또에게 - 마니또 탭
    'mission_accept': 0.obs, // 생성자에게 - 미션 탭
    'mission_guess': 0.obs, // 생성자에게 - 미션 탭
    'mission_complete': 0.obs, // 마니또에게 - 포스트 탭
  };
  // 댓글 버튼 뱃지
  final badgeComment = <String, RxInt>{}.obs;
  // 미션 바텀 버튼 뱃지
  final RxInt badgeMissionCount = RxInt(0);
  // 포스트 바텀 버튼 뱃지
  final RxInt badgePostCount = RxInt(0);

  @override
  void onInit() {
    super.onInit();
    // 값이 바뀌면 바뀜
    badgeMap['mission_accept']?.listen((_) => updateBadgeMissionCount());
    badgeMap['mission_guess']?.listen((_) => updateBadgeMissionCount());
    badgeMap['mission_complete']?.listen((_) => updateBadgePostCount());
  }

  /// 값을 업데이트 하는 함수 - 댓글
  void addBadgeComment(missionId) {
    if (badgeComment.containsKey(missionId)) {
      badgeComment[missionId]!.value += 1;
    } else {
      badgeComment[missionId] = RxInt(1);
    }
    updateBadgePostCount();
  }

  /// 값을 업데이트 하는 함수 - 미션 뱃지
  void updateBadgeMissionCount() {
    badgeMissionCount.value =
        (badgeMap['mission_accept']?.value ?? 0) +
        (badgeMap['mission_guess']?.value ?? 0);
  }

  /// 값을 업데이트 하는 함수 - 포스트 뱃지
  void updateBadgePostCount() {
    int totalCount = 0;
    badgeComment.forEach((key, rxIntValue) => totalCount += rxIntValue.value);
    totalCount += badgeMap['mission_complete']!.value;
    badgePostCount.value = totalCount;
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
      badgeMap.forEach((key, value) => value.value = 0);

      // 데이터 삽입
      for (final item in data) {
        final badgeType = item['badge_type'];
        final count = item['count'] ?? 0;

        // 댓글 뱃지를 제외한 모든 뱃지 들어감
        if (badgeType != null && badgeMap.containsKey(badgeType)) {
          badgeMap[badgeType]?.value = count;
        }
        // 오직 댓글 뱃지만 추가
        else {
          badgeComment[badgeType] = RxInt(count);
        }
      }
      updateBadgeMissionCount();
      updateBadgePostCount();
    } catch (e) {
      debugPrint('fetchExistingBadges Error: $e');
    }
  }

  /// 해당 뱃지 초기화
  Future<void> resetBadgeCount(String badgeType) async {
    try {
      bool shouldUpdateSupabase = false;

      if (badgeMap.containsKey(badgeType) && badgeMap[badgeType]?.value != 0) {
        badgeMap[badgeType]?.value = 0;
        shouldUpdateSupabase = true;
        updateBadgeMissionCount();
        updateBadgePostCount();
      } else if (badgeComment.containsKey(badgeType) &&
          badgeComment[badgeType]?.value != 0) {
        badgeComment[badgeType]?.value = 0;
        shouldUpdateSupabase = true;
        updateBadgePostCount();
      }

      if (shouldUpdateSupabase) {
        await _supabase
            .from('badges')
            .update({'count': 0})
            .eq('user_id', _supabase.auth.currentUser!.id)
            .eq('badge_type', badgeType);
      }
    } catch (e) {
      debugPrint('resetBadgeCount: $e');
    }
  }
}
