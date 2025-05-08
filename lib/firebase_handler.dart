import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/badge_controller.dart';
import 'package:manito/controllers/manito_controller.dart';
import 'package:manito/controllers/mission_controller.dart';
import 'package:manito/controllers/post_controller.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 포그라운드 메시지 처리 - 데이터 새로고침, 뱃지 기능 추가 필요
void handleForegroundMessage(RemoteMessage message) async {
  final PostController postController = Get.find<PostController>();
  final ManitoController manitoController = Get.find<ManitoController>();
  final MissionController missionController = Get.find<MissionController>();
  final BadgeController badgeController = Get.find<BadgeController>();
  final prefs = await SharedPreferences.getInstance();

  // 친구 신청
  if (message.data['type'] == 'friend_request') {
    badgeController.friendRequestBadge.value = true;
    await prefs.setBool('friend_request', true);
    customSnackbar(
      title: message.notification!.title!,
      message: message.notification!.body!,
    );
  }
  // 미션 제의
  else if (message.data['type'] == 'mission_propose') {
    await manitoController.fetchMissionProposeList();
    badgeController.missonProposeBadge.value = true;
    await prefs.setBool('mission_propose', true);
    customSnackbar(
      title: message.notification!.title!,
      message: message.notification!.body!,
    );
  }
  // 마니또가 미션을 수락
  else if (message.data['type'] == 'update_mission_progress') {
    await missionController.fetchMyMissions();
    badgeController.missionBadge.value = true;
    await prefs.setBool('update_mission', true);
    customSnackbar(
      title: message.notification!.title!,
      message: message.notification!.body!,
    );
  }
  // 마니또가 미션을 완료
  else if (message.data['type'] == 'update_mission_done') {
    await missionController.fetchMyMissions();
    badgeController.missionBadge.value = true;
    await prefs.setBool('update_mission', true);
    customSnackbar(
      title: message.notification!.title!,
      message: message.notification!.body!,
    );
  }
  // 생성자가 추측을 완료
  else if (message.data['type'] == 'update_mission_guess') {
    await postController.fetchPosts();
    await postController.fetchIncompletePost();
    customSnackbar(
      title: message.notification!.title!,
      message: message.notification!.body!,
    );
  }
  // 새로운 댓글
  else if (message.data['type'] == 'insert_comment') {
    final String missionId = message.data['mission_id'];
    badgeController.postBadge[missionId] = true.obs;
    badgeController.updateHasAnyPost();
    await prefs.setBool('post_$missionId', true);
  }
  // 새로운 채팅
  else if (message.data['type'] == 'insert_chat') {
    final String missionId = message.data['mission_id'];
    badgeController.postBadge[missionId] = true.obs;
    badgeController.updateHasAnyPost();
    await prefs.setBool('post_$missionId', true);
  }
}

/// 백그라운드 메시지 처리 - 뱃지 기능
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint("handleBackgroundMessage 동작");
  final prefs = await SharedPreferences.getInstance();

  // 친구 신청
  if (message.data['type'] == 'friend_request') {
    await prefs.setBool('friend_request', true);
    debugPrint('friend_request: ${prefs.getBool('friend_request')}');
  }
  // 미션 제의
  else if (message.data['type'] == 'mission_propose') {
    await prefs.setBool('mission_propose', true);
    debugPrint('mission_propose: ${prefs.getBool('mission_propose')}');
  }
  // 마니또가 미션을 수락
  else if (message.data['type'] == 'update_mission_progress') {
    await prefs.setBool('update_mission', true);
    debugPrint('update_mission: ${prefs.getBool('update_mission')}');
  }
  // 마니또가 미션을 완료
  else if (message.data['type'] == 'update_mission_done') {
    await prefs.setBool('update_mission', true);
    debugPrint('update_mission: ${prefs.getBool('update_mission')}');
  }
  // 생성자가 추측을 완료
  else if (message.data['type'] == 'update_mission_guess') {
    String missionId = message.data['mission_id'];
    await prefs.setBool('post_$missionId', true);
    debugPrint('post: ${prefs.getBool('post_$missionId')}');
  }
  // 댓글 뱃지
  else if (message.data['type'] == 'insert_comment') {
    String missionId = message.data['mission_id'];
    await prefs.setBool('post_$missionId', true);
    debugPrint('post: ${prefs.getBool('post_$missionId')}');
  }
  // 채팅 뱃지
  else if (message.data['type'] == 'insert_chat') {
    String missionId = message.data['mission_id'];
    await prefs.setBool('post_$missionId', true);
    debugPrint('post: ${prefs.getBool('post_$missionId')}');
  }
}
