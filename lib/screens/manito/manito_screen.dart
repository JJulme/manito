import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/controllers/manito_controller.dart';
import 'package:manito/models/mission.dart';
import 'package:manito/models/user_profile.dart';
import 'package:manito/screens/manito/auto_reply_screen.dart';
import 'package:manito/screens/manito/manito_post_screen.dart';
import 'package:manito/screens/manito/mission_propose_screen.dart';
import 'package:manito/widgets/admob/banner_ad_widget.dart';
import 'package:manito/widgets/mission/custom_slide.dart';
import 'package:manito/widgets/mission/profile_mission.dart';
import 'package:manito/widgets/mission/timer.dart';

class ManitoScreen extends StatefulWidget {
  const ManitoScreen({super.key});

  @override
  State<ManitoScreen> createState() => _ManitoScreenState();
}

class _ManitoScreenState extends State<ManitoScreen>
    with WidgetsBindingObserver {
  final ManitoController _controller = Get.find<ManitoController>();
  final FriendsController _friendsController = Get.find<FriendsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _controller.isLoading.value = true;
      _controller.fetchMissionProposeList();
      _controller.fetchMissionAcceptList();
      _controller.isLoading.value = false;
    }
  }

  /// 미션 제안 상세 페이지 이동
  Future<void> _toMissionProposeScreen(
    String missionId,
    UserProfile creatorProfile,
  ) async {
    final result = await Get.to(
      () => MissionProposeScreen(),
      arguments: [missionId, creatorProfile],
    );
    if (result == true) {
      await _controller.fetchMissionProposeList();
      await _controller.fetchMissionAcceptList();
    }
  }

  /// 미션 게시물 작성 페이지 이동
  Future<void> _toMissionPostScreen(
    MissionAccept mission,
    UserProfile creatorProfile,
  ) async {
    final result = await Get.to(
      () => ManitoPostScreen(),
      arguments: [mission, creatorProfile],
    );
    if (result == true) {
      await _controller.fetchMissionAcceptList();
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = Get.width;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0.07 * width,
        title: Text('마니또 미션', style: Get.textTheme.headlineLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.reply_rounded, size: 0.07 * width),
            onPressed: () => Get.to(() => AutoReplyScreen()),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (_controller.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                // SizedBox(height: 0.02 * di),
                // 광고
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0.03 * width),
                  child: BannerAdWidget(
                    borderRadius: 0.02 * width,
                    width: Get.width - 0.06 * width,
                    androidAdId: dotenv.env['BANNER_MANITO_ANDROID']!,
                    iosAdId: dotenv.env['BANNER_MANITO_IOS']!,
                  ),
                ),
                SizedBox(height: 0.03 * width),
                // 수락가능, 진행중 미션 둘다 없을 경우 진행중인 미션이 없다고 안내.
                _controller.missionAcceptList.length +
                            _controller.missionProposeList.length ==
                        0
                    ? Container(
                      height: Get.height * 0.5,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Text('진행중인 미션이 없습니다.'),
                    )
                    : SizedBox.shrink(),

                // 수락 가능 목록
                _missionProposeList(width),
                // 진행중 목록
                _missionAcceptList(width),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// 수락가능 미션 목록
  Obx _missionProposeList(double width) {
    return Obx(() {
      if (_controller.missionProposeList.isEmpty) {
        return SizedBox.shrink();
      } else {
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _controller.missionProposeList.length,
          itemBuilder: (context, index) {
            // 미션 정보
            final missionPropose = _controller.missionProposeList[index];
            // 친구 정보
            final UserProfile? creatorProfile = _friendsController
                .searchFriendProfile(missionPropose.creatorId);
            return GestureDetector(
              onTap:
                  () => _toMissionProposeScreen(
                    missionPropose.id,
                    creatorProfile!,
                  ),
              child: Container(
                height: 0.22 * width,
                padding: EdgeInsets.symmetric(
                  vertical: 0.03 * width,
                  horizontal: 0.03 * width,
                ),
                margin: EdgeInsets.only(
                  left: 0.03 * width,
                  right: 0.03 * width,
                  bottom: 0.03 * width,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(0.02 * width),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.red),
                    Text(' 미션 도착 ', style: Get.textTheme.titleMedium),
                    Tooltip(
                      showDuration: Duration(days: 1),
                      triggerMode: TooltipTriggerMode.tap,
                      message: '모든 미션은 선착순 1명',
                      child: Icon(Icons.help_outline_rounded, color: kGrey),
                    ),
                    Spacer(),
                    TimerWidget(
                      targetDateTimeString: missionPropose.acceptDeadline,
                      fontSize: 0.07 * width,
                      onTimerComplete:
                          () => _controller.fetchMissionProposeList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    });
  }

  /// 진행중 미션 목록
  Obx _missionAcceptList(double width) {
    return Obx(() {
      if (_controller.missionAcceptList.isEmpty) {
        return SizedBox.shrink();
      } else {
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _controller.missionAcceptList.length,
          itemBuilder: (context, index) {
            final MissionAccept missionAccept =
                _controller.missionAcceptList[index];
            final UserProfile? creatorProfile = _friendsController
                .searchFriendProfile(missionAccept.creatorId);
            return CustomSlide(
              mainWidget: Container(
                width: width - 0.06 * width,
                height: 0.22 * width,
                padding: EdgeInsets.all(0.03 * width),
                margin: EdgeInsets.only(
                  left: 0.03 * width,
                  right: 0.03 * width,
                  bottom: 0.03 * width,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(0.02 * width),
                ),
                child: Row(
                  children: [
                    Icon(Icons.run_circle_sharp, color: Colors.amber[900]),
                    Text(' 진행중 미션', style: Get.textTheme.titleMedium),
                    Spacer(),
                    Icon(Icons.timer_outlined),
                    SizedBox(width: 0.02 * width),
                    TimerWidget(
                      targetDateTimeString: missionAccept.deadline,
                      fontSize: 0.07 * width,
                      onTimerComplete:
                          () => _controller.fetchMissionAcceptList(),
                    ),
                  ],
                ),
              ),
              subWidget: Container(
                width: width - 0.06 * width,
                height: 0.22 * width,
                padding: EdgeInsets.all(0.03 * width),
                margin: EdgeInsets.only(
                  left: 0.03 * width,
                  right: 0.03 * width,
                  bottom: 0.03 * width,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(0.02 * width),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ProfileAndMission(
                      creatorProfileUrl: creatorProfile!.profileImageUrl!,
                      size: 0.14 * width,
                      creatorNickname: '${creatorProfile.nickname} 에게',
                      content: missionAccept.content,
                    ),
                    IconButton(
                      padding: const EdgeInsets.all(0),
                      iconSize: 0.1 * width,
                      icon: const Icon(Icons.edit_note),
                      onPressed:
                          () => _toMissionPostScreen(
                            missionAccept,
                            creatorProfile,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    });
  }
}
