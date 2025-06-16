import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/models/mission.dart';
import 'package:manito/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MissionController extends GetxController {
  final _supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var pendingMyMissions = <MyMission>[].obs; // 내가 만든 대기중 미션
  var acceptMyMissions = <MyMission>[].obs; // 내가 만든 진행중 미션
  var completeMyMissions = <MyMission>[].obs; // 미개봉 종료 미션

  @override
  void onInit() async {
    super.onInit();
    await fetchMyMissions();
  }

  /// 내가 생성한 미션 리스트 가져오는 함수 - 대기, 진행중, 완료
  Future<void> fetchMyMissions() async {
    isLoading.value = true;
    final String userId = _supabase.auth.currentUser!.id;
    final FriendsController friendsController = Get.find<FriendsController>();
    try {
      // 추측이 이루어 지지 않은 데이터만 가져옴
      final List<dynamic> missionsData = await _supabase
          .from('missions')
          .select(
            'id, friend_ids, status, deadline_type, deadline, accept_deadline',
          )
          .eq('creator_id', userId)
          .isFilter('guess', null);

      List<MyMission> allMissions = [];
      // 각 미션 반복문으로 친구들 id를 통해 프로필 넣어줌
      for (var mission in missionsData) {
        List<FriendProfile> friendProfiles = friendsController
            .searchFriendProfiles(mission['friend_ids']);
        var myMission = MyMission.fromJson(mission, friendProfiles);
        allMissions.add(myMission);
      }

      pendingMyMissions.value =
          allMissions.where((mission) => mission.status == '대기중').toList();
      acceptMyMissions.value =
          allMissions.where((mission) => mission.status == '진행중').toList();
      completeMyMissions.value =
          allMissions.where((mission) => mission.status == '추측중').toList();
    } catch (e) {
      debugPrint('fetchMyMissions Error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

/// 미션 생성 컨트롤러
class MissionCreateController extends GetxController {
  final _supabase = Supabase.instance.client;
  var isLoading = false.obs;
  // 선택된 친구 ID 목록
  var selectedFriends = <FriendProfile>[].obs;

  /// 체크 상태 토글 함수
  void toggleSelection(FriendProfile friendProfile) {
    if (selectedFriends.contains(friendProfile)) {
      selectedFriends.remove(friendProfile);
    } else {
      selectedFriends.add(friendProfile);
    }
  }

  /// 체크 상태 확인 함수
  bool isSelected(FriendProfile friendProfile) {
    return selectedFriends.contains(friendProfile);
  }

  /// 미션 생성 - 친구의 순서를 랜덤으로 보내게 되는데 필요 없는 기능일 수 있음
  Future<String> createMission(int selectedIndex) async {
    isLoading.value = true;
    final List<String?> friendsIds =
        selectedFriends.map((friend) => friend.id).toList();
    try {
      final String result = await _supabase.rpc(
        'create_mission',
        params: {
          'creator_id': _supabase.auth.currentUser!.id,
          'friend_ids': friendsIds,
          'deadline_type': selectedIndex == 0 ? '하루' : '한주',
        },
      );

      // 뒤로가기 새로고침 요청
      Get.back(result: true);
      return result;
    } catch (e) {
      debugPrint('createMission Error: $e');
      return 'create_mission_error';
    } finally {
      isLoading.value = false;
    }
  }
}

/// 미션 추측 작성 컨트롤러
class MissionGuessController extends GetxController {
  final _supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var updateLoading = false.obs;
  // 가져올 미션 정보
  late MyMission completeMission;
  final TextEditingController descController = TextEditingController();

  @override
  void onInit() async {
    super.onInit();
    completeMission = Get.arguments;
  }

  /// 미션 추측 업데이트 - 수정 필요
  Future<String> updateMissionGuess() async {
    updateLoading.value = true;
    try {
      await _supabase.rpc(
        'mission_complete',
        params: {
          'p_mission_id': completeMission.id,
          'p_guess': descController.text,
        },
      );
      Get.back(result: true);
      return 'guess_update_success';
    } catch (e) {
      debugPrint('updateMissionGuess Error: $e');
      return 'guess_updage_error';
    } finally {
      updateLoading.value = false;
    }
  }
}
