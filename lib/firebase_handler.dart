import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/badge_controller.dart';
import 'package:manito/controllers/manito_controller.dart';
import 'package:manito/controllers/mission_controller.dart';
import 'package:manito/controllers/post_controller.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';

/// 포그라운드 메시지 처리 - 데이터 새로고침, 뱃지 기능 추가 필요
void handleForegroundMessage(RemoteMessage message) async {
  final PostController postController = Get.find<PostController>();
  final ManitoController manitoController = Get.find<ManitoController>();
  final MissionController missionController = Get.find<MissionController>();
  final BadgeController badgeController = Get.find<BadgeController>();

  void showLocalizedSnackbar(String keySuffix, {List<String>? args}) {
    final String titleKey = "firebase_handler.${keySuffix}_title";
    final String bodyKey = "firebase_handler.${keySuffix}_body";
    String snackTitle = Get.context!.tr(titleKey);
    String snackMessage = Get.context!.tr(
      bodyKey,
      args: args,
    ); // args를 GetX tr()에 전달

    customSnackbar(title: snackTitle, message: snackMessage);
  }

  // 친구 신청
  if (message.data['type'] == 'friend_request') {
    badgeController.badgeMap['friend_request']!.value++;
    showLocalizedSnackbar("friend_request");
  }
  // 미션 제의
  else if (message.data['type'] == 'mission_propose') {
    await manitoController.fetchMissionProposeList();
    badgeController.badgeMap['mission_propose']!.value++;
    showLocalizedSnackbar("mission_propose");
  }
  // 마니또가 미션을 수락
  else if (message.data['type'] == 'update_mission_progress') {
    await missionController.fetchMyMissions();
    badgeController.badgeMap['mission_accept']!.value++;
    badgeController.updateBadgeMissionCount();
    showLocalizedSnackbar("mission_accept");
  }
  // 마니또가 미션을 완료
  else if (message.data['type'] == 'update_mission_guess') {
    await missionController.fetchMyMissions();
    badgeController.badgeMap['mission_guess']!.value++;
    badgeController.updateBadgeMissionCount();
    showLocalizedSnackbar("mission_guess");
  }
  // 생성자가 추측을 완료
  else if (message.data['type'] == 'update_mission_complete') {
    await manitoController.fetchMissionGuessList();
    await postController.fetchPosts();
    badgeController.badgeMap['mission_complete']!.value++;
    badgeController.updateBadgePostCount();
    showLocalizedSnackbar("mission_complete");
  }
  // 새로운 댓글
  else if (message.data['type'] == 'insert_comment') {
    final String missionId = message.data['mission_id'];
    badgeController.addBadgeComment(missionId);
  }
  // 새로운 채팅
  // else if (message.data['type'] == 'insert_chat') {
  //   final String missionId = message.data['mission_id'];
  // }
}

// /// 백그라운드 메시지 처리 - 뱃지 기능
// @pragma('vm:entry-point')
// Future<void> handleBackgroundMessage(RemoteMessage message) async {
//   debugPrint("handleBackgroundMessage 동작");
//   final prefs = await SharedPreferences.getInstance();

//   // 친구 신청
//   if (message.data['type'] == 'friend_request') {
//     await prefs.setBool('friend_request', true);
//     debugPrint('friend_request: ${prefs.getBool('friend_request')}');
//   }
//   // 미션 제의
//   else if (message.data['type'] == 'mission_propose') {
//     await prefs.setBool('mission_propose', true);
//     debugPrint('mission_propose: ${prefs.getBool('mission_propose')}');
//   }
//   // 마니또가 미션을 수락
//   else if (message.data['type'] == 'update_mission_progress') {
//     await prefs.setBool('update_mission', true);
//     debugPrint('update_mission: ${prefs.getBool('update_mission')}');
//   }
//   // 마니또가 미션을 완료
//   else if (message.data['type'] == 'update_mission_done') {
//     await prefs.setBool('update_mission', true);
//     debugPrint('update_mission: ${prefs.getBool('update_mission')}');
//   }
//   // 생성자가 추측을 완료
//   else if (message.data['type'] == 'update_mission_guess') {
//     String missionId = message.data['mission_id'];
//     await prefs.setBool('post_$missionId', true);
//     debugPrint('post: ${prefs.getBool('post_$missionId')}');
//   }
//   // 댓글 뱃지
//   else if (message.data['type'] == 'insert_comment') {
//     String missionId = message.data['mission_id'];
//     await prefs.setBool('post_$missionId', true);
//     debugPrint('post: ${prefs.getBool('post_$missionId')}');
//   }
//   // 채팅 뱃지
//   else if (message.data['type'] == 'insert_chat') {
//     String missionId = message.data['mission_id'];
//     await prefs.setBool('post_$missionId', true);
//     debugPrint('post: ${prefs.getBool('post_$missionId')}');
//   }
// }
