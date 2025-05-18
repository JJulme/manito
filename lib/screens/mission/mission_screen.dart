import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/badge_controller.dart';
import 'package:manito/controllers/mission_controller.dart';
import 'package:manito/models/mission.dart';
import 'package:manito/screens/mission/mission_create_screen.dart';
import 'package:manito/screens/mission/mission_guess_screen.dart';
import 'package:manito/widgets/admob/banner_ad_widget.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:manito/widgets/mission/timer.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen>
    with WidgetsBindingObserver {
  final MissionController _controller = Get.find<MissionController>();
  final BadgeController _badgeController = Get.find<BadgeController>();

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
      _controller.fetchMyMissions();
    }
  }

  /// 미션 생성 화면 이동
  Future<void> _toMissionCreateScreen() async {
    // 미션 생성 개수 제한
    if (_controller.pendingMyMissions.length +
            _controller.acceptMyMissions.length >
        2) {
      customSnackbar(title: '알림', message: '미션은 최대 3개 만들 수 있습니다.');
    } else {
      final result = await Get.to(() => MissionCreateScreen());
      if (result == true) {
        await _controller.fetchMyMissions();
      }
    }
  }

  /// 미션 추측 화면 이동
  Future<void> _toMissionGuessScreen(MyMission myMission) async {
    bool result = await Get.to(
      () => MissionGuessScreen(),
      arguments: myMission,
    );
    if (result) {
      _controller.fetchMyMissions();
      _badgeController.badgeMap['mission_complete']!.value++;
      _badgeController.updateBadgePostCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0.07 * width,
        title: Text('나의 미션', style: Get.textTheme.headlineLarge),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 0.02 * width),
            child: IconButton(
              icon: Icon(Icons.refresh, size: 0.07 * width),
              onPressed: () {
                _controller.fetchMyMissions();
              },
            ),
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
                // 생성 버튼 - 생성 미션의 개수가 3개 미만이면 생김
                _buildCreateMissionButton(width),
                // 광고
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0.03 * width),
                  child: BannerAdWidget(
                    borderRadius: 0.02 * width,
                    width: Get.width - 0.06 * width,
                    androidAdId: dotenv.env['BANNER_MISSION_ANDROID']!,
                    iosAdId: dotenv.env['BANNER_MISSION_IOS']!,
                  ),
                ),
                SizedBox(height: 0.03 * width),
                // 완료 미션 목록
                _completeMyMissions(width),

                // 대기중 미션 목록
                _pendingMyMissions(width),

                // 진행중 미션 목록
                _acceptMyMissions(width),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// 생성 버튼
  Widget _buildCreateMissionButton(double width) {
    final totalMissions =
        _controller.pendingMyMissions.length +
        _controller.acceptMyMissions.length;
    return totalMissions < 3
        ? Container(
          width: width - 0.06 * width,
          height: (width - 0.06 * width) * 0.15,
          margin: EdgeInsets.only(
            left: 0.03 * width,
            right: 0.03 * width,
            bottom: 0.03 * width,
          ),
          child: ElevatedButton(
            onPressed: _toMissionCreateScreen,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 0.07 * width, color: Colors.black),
                Text(' 미션 만들기', style: Get.textTheme.bodyLarge),
              ],
            ),
          ),
        )
        : const SizedBox.shrink();
  }

  /// 완료된 내 미션
  Obx _completeMyMissions(double width) {
    return Obx(() {
      if (_controller.completeMyMissions.isEmpty) {
        return SizedBox.shrink();
      } else {
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _controller.completeMyMissions.length,
          itemBuilder: (context, index) {
            final myMission = _controller.completeMyMissions[index];
            return GestureDetector(
              child: Container(
                height: (width - 0.06 * width) * 0.15,
                padding: EdgeInsets.symmetric(
                  vertical: 0.016 * width,
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
                    Icon(Icons.check_circle_sharp, color: Colors.green),
                    SizedBox(width: 0.02 * width),
                    Text('완료된 미션 도착!', style: Get.textTheme.titleMedium),
                  ],
                ),
              ),
              onTap: () async {
                await _toMissionGuessScreen(myMission);
              },
            );
          },
        );
      }
    });
  }

  /// 수락 대기중 내 미션
  Obx _pendingMyMissions(double width) {
    return Obx(() {
      if (_controller.pendingMyMissions.isEmpty) {
        return SizedBox.shrink();
      } else {
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _controller.pendingMyMissions.length,
          itemBuilder: (context, index) {
            final myMission = _controller.pendingMyMissions[index];
            return Container(
              padding: EdgeInsets.symmetric(
                vertical: 0.016 * width,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(Icons.error_sharp, color: Colors.amber),
                      SizedBox(width: 0.02 * width),

                      Text(myMission.status, style: Get.textTheme.titleMedium),
                      SizedBox(width: 0.01 * width),
                      Text('(${myMission.deadlineType}) '),
                      Tooltip(
                        showDuration: Duration(days: 1),
                        triggerMode: TooltipTriggerMode.tap,
                        message: '남은 시간까지 수락한 친구가 없다면 자동으로 삭제됩니다.',
                        child: Icon(Icons.help_outline_rounded, color: kGrey),
                      ),
                      Spacer(),
                      TimerWidget(
                        targetDateTimeString: myMission.acceptDeadline!,
                        fontSize: 0.05 * width,
                        onTimerComplete: () => _controller.fetchMyMissions(),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.02 * width),
                  // 친구 목록
                  SizedBox(
                    height: 0.22 * width,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      separatorBuilder:
                          (context, index) => SizedBox(width: 0.02 * width),
                      itemCount: myMission.friendsProfile.length,
                      itemBuilder: (context, index) {
                        final friendProfile = myMission.friendsProfile[index];
                        return SizedBox(
                          width: 0.15 * width,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              profileImageOrDefault(
                                friendProfile.profileImageUrl,
                                0.15 * width,
                              ),
                              Text(
                                friendProfile.nickname,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    });
  }

  /// 진행중 내 미션
  Obx _acceptMyMissions(double width) {
    return Obx(() {
      if (_controller.acceptMyMissions.isEmpty) {
        return SizedBox.shrink();
      } else {
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _controller.acceptMyMissions.length,
          itemBuilder: (context, index) {
            final acceptMission = _controller.acceptMyMissions[index];
            return Container(
              padding: EdgeInsets.symmetric(
                vertical: 0.016 * width,
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
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(Icons.run_circle_sharp, color: Colors.deepOrange),
                      SizedBox(width: 0.02 * width),
                      Text(
                        acceptMission.status,
                        style: Get.textTheme.titleMedium,
                      ),
                      SizedBox(width: 0.01 * width),
                      Text('(${acceptMission.deadlineType}) '),
                      Tooltip(
                        showDuration: Duration(days: 1),
                        triggerMode: TooltipTriggerMode.tap,
                        message: '마니또가 미션을 진행중 입니다.',
                        child: Icon(Icons.help_outline_rounded, color: kGrey),
                      ),
                      Spacer(),
                      TimerWidget(
                        targetDateTimeString: acceptMission.deadline,
                        fontSize: 0.054 * width,
                        onTimerComplete: () => _controller.fetchMyMissions(),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.02 * width),
                  // 친구 목록
                  SizedBox(
                    height: 0.22 * width,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      separatorBuilder:
                          (context, index) => SizedBox(width: 0.02 * width),
                      itemCount: acceptMission.friendsProfile.length,
                      itemBuilder: (context, index) {
                        final userProfile = acceptMission.friendsProfile[index];
                        return SizedBox(
                          width: 0.14 * width,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              profileImageOrDefault(
                                userProfile.profileImageUrl!,
                                0.14 * width,
                              ),
                              Text(
                                userProfile.nickname,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    });
  }
}
