import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/models/mission.dart';
import 'package:manito/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// /// 기본 미션 화면 컨트롤러
// class MissionController extends GetxController {
//   final _supabase = Supabase.instance.client;
//   var pendingMyMissions = <MyMission>[].obs; // 내가 만든 대기중 미션
//   var acceptMyMissions = <MyMission>[].obs; // 내가 만든 진행중 미션
//   var completeMyMissions = <MyMission>[].obs; // 미개봉 종료 미션
//   var missionProposeList = <MissionProposeList>[].obs; // 수락가능 미션
//   var missionAcceptList = <MissionAccept>[].obs; // 진행중 미션
//   // 탭 로딩
//   var tabLoading1 = false.obs;
//   var tabLoading2 = false.obs;

//   @override
//   void onInit() async {
//     super.onInit();
//     fetchMissionProposeList();
//     fetchMissionAcceptList();
//     await fetchMyMissions();
//   }

//   /// 내가 생성한 미션 리스트 가져오는 함수 - 대기, 진행중, 완료
//   Future<void> fetchMyMissions() async {
//     tabLoading2.value = true;
//     final String userId = _supabase.auth.currentUser!.id;
//     final FriendsController friendsController = Get.find<FriendsController>();
//     try {
//       // 추측이 이루어 지지 않은 데이터만 가져옴
//       final List<dynamic> missionsData = await _supabase
//           .from('missions')
//           .select(
//               'id, friend_ids, status, deadline_type, deadline, accept_deadline')
//           .eq('creator_id', userId)
//           .isFilter('guess', null);

//       List<MyMission> allMissions = [];
//       // 각 미션 반복문으로 친구들 id를 통해 프로필 넣어줌
//       for (var mission in missionsData) {
//         List<UserProfile> friendProfiles =
//             friendsController.searchFriendProfiles(mission['friend_ids']);
//         var myMission = MyMission.fromJson(mission, friendProfiles);
//         allMissions.add(myMission);
//       }
//       pendingMyMissions.value =
//           allMissions.where((mission) => mission.status == '대기중').toList();
//       acceptMyMissions.value =
//           allMissions.where((mission) => mission.status == '진행중').toList();
//       completeMyMissions.value =
//           allMissions.where((mission) => mission.status == '완료').toList();
//     } catch (e) {
//       debugPrint('fetchMyMissions Error: $e');
//     } finally {
//       tabLoading2.value = false;
//     }
//   }

//   /// 나에게 온 미션 제의 목록 가져오는 함수
//   Future<void> fetchMissionProposeList() async {
//     tabLoading1.value = true;
//     try {
//       final List<dynamic> data = await _supabase
//           .from('mission_propose')
//           .select('id, missions:mission_id(creator_id, accept_deadline)')
//           .eq('friend_id', _supabase.auth.currentUser!.id);

//       missionProposeList.value =
//           data.map((e) => MissionProposeList.fromJson(e)).toList();
//     } catch (e) {
//       debugPrint('fetchMissionProposeList Error: $e');
//     } finally {
//       tabLoading1.value = false;
//     }
//   }

//   // 내가 수락한 미션 목록 가져오기
//   Future<void> fetchMissionAcceptList() async {
//     tabLoading1.value = true;
//     try {
//       final List<dynamic> data = await _supabase
//           .from('mission_posts')
//           .select('''id,
//               content,
//               status,
//               missions:mission_posts_id_fkey(creator_id, deadline, deadline_type)
//               ''')
//           .eq('manito_id', _supabase.auth.currentUser!.id)
//           .eq('status', '진행중');
//       missionAcceptList.value =
//           data.map((e) => MissionAccept.fromJson(e)).toList();
//     } catch (e) {
//       debugPrint('fetchMissionAcceptList Error: $e');
//     } finally {
//       tabLoading1.value = false;
//     }
//   }
// }

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
        List<UserProfile> friendProfiles = friendsController
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
  var selectedFriends = <UserProfile>[].obs;

  /// 체크 상태 토글 함수
  void toggleSelection(UserProfile friendProfile) {
    if (selectedFriends.contains(friendProfile)) {
      selectedFriends.remove(friendProfile);
    } else {
      selectedFriends.add(friendProfile);
    }
  }

  /// 체크 상태 확인 함수
  bool isSelected(UserProfile friendProfile) {
    return selectedFriends.contains(friendProfile);
  }

  /// 미션 생성 - 친구의 순서를 랜덤으로 보내게 되는데 필요 없는 기능일 수 있음
  Future<String> createMission(int selectedIndex) async {
    isLoading.value = true;
    final List<String> friendsIds =
        selectedFriends.map((friend) => friend.id).toList()..shuffle();
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
      return '오류: $e';
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
      await _supabase
          .from('missions')
          .update({'status': '완료', 'guess': descController.text})
          .eq('id', completeMission.id);
      Get.back(result: true);
      return '마니또가 누구인지 확인해보세요!';
    } catch (e) {
      debugPrint('updateMissionGuess Error: $e');
      return '실패';
    } finally {
      updateLoading.value = false;
    }
  }
}
