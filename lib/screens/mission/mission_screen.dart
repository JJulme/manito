import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/badge_controller.dart';
import 'package:manito/controllers/mission_controller.dart';
import 'package:manito/custom_icons.dart';
import 'package:manito/models/mission.dart';
import 'package:manito/screens/mission/mission_create_screen.dart';
import 'package:manito/screens/mission/mission_create_screen_new.dart';
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
  static const int _maxMissions = 3;

  // Constants for responsive design
  static const double _horizontalPadding = 0.03;
  static const double _verticalPadding = 0.016;
  static const double _containerSpacing = 0.03;
  static const double _iconSize = 0.06;
  static const double _refreshIconSize = 0.07;
  static const double _borderRadius = 0.02;
  static const double _titleSpacing = 0.07;
  static const double _buttonHeight = 0.14;
  static const double _friendsListHeight = 0.22;
  static const double _pendingProfileSize = 0.15;
  static const double _acceptProfileSize = 0.14;
  static const double _itemSpacing = 0.02;
  static const double _smallSpacing = 0.01;
  static const double _timerFontSize = 0.054;

  late final MissionController _controller;
  late final BadgeController _badgeController;

  int get _totalActiveMissions =>
      _controller.pendingMyMissions.length +
      _controller.acceptMyMissions.length;

  bool get _canCreateMission => _totalActiveMissions < _maxMissions;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<MissionController>();
    _badgeController = Get.find<BadgeController>();
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

  // 미션 생성 화면 이동
  Future<void> _toMissionCreateScreen() async {
    // 미션 생성 개수 제한
    if (_controller.pendingMyMissions.length +
            _controller.acceptMyMissions.length >
        2) {
      customSnackbar(
        title: context.tr("mission_screen.max_snack_title"),
        message: context.tr("mission_screen.max_snack_message"),
      );
    } else {
      final result = await Get.to(() => MissionCreateScreen());
      if (result == true) {
        await _controller.fetchMyMissions();
      }
    }
  }

  // 미션 추측 화면 이동
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

  // 본체
  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return Scaffold(
      appBar: _buildAppBar(width),
      body: SafeArea(
        child: Obx(() {
          if (_controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildMissionList(width);
        }),
      ),
    );
  }

  // 앱바
  AppBar _buildAppBar(double screenWidth) {
    return AppBar(
      centerTitle: false,
      titleSpacing: screenWidth * _titleSpacing,
      title:
          Text("mission_screen.title", style: Get.textTheme.headlineLarge).tr(),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: screenWidth * _itemSpacing),
          child: IconButton(
            icon: Icon(Icons.refresh, size: screenWidth * _refreshIconSize),
            onPressed: _controller.fetchMyMissions,
          ),
        ),
      ],
    );
  }

  // 바디
  Widget _buildMissionList(double screenWidth) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCreateMissionButton(screenWidth),
          _buildBannerAd(screenWidth),
          SizedBox(height: screenWidth * _containerSpacing),
          _buildCompleteMissions(screenWidth),
          _buildPendingMissions(screenWidth),
          _buildAcceptMissions(screenWidth),
        ],
      ),
    );
  }

  // 미션 생성 버튼
  Widget _buildCreateMissionButton(double screenWidth) {
    if (!_canCreateMission) return const SizedBox.shrink();

    return Container(
      width: double.maxFinite,
      height: screenWidth * _buttonHeight,
      margin: EdgeInsets.only(
        // left: screenWidth * _horizontalPadding,
        // right: screenWidth * _horizontalPadding,
        bottom: screenWidth * _containerSpacing,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * _horizontalPadding,
      ),
      child: ElevatedButton(
        onLongPress: () => Get.to(() => MissionCreateScreenNew()),
        onPressed: _toMissionCreateScreen,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CustomIcons.star_add2, size: screenWidth * _iconSize),
            SizedBox(width: screenWidth * 0.03),
            Text("mission_screen.create_mission_btn").tr(),
          ],
        ),
      ),
    );
  }

  // 광고
  Widget _buildBannerAd(double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * _horizontalPadding,
      ),
      child: BannerAdWidget(
        borderRadius: screenWidth * _borderRadius,
        width: screenWidth - (_horizontalPadding * 2) * screenWidth,
        androidAdId: dotenv.env['BANNER_MISSION_ANDROID']!,
        iosAdId: dotenv.env['BANNER_MISSION_IOS']!,
      ),
    );
  }

  // 완료된 미션 리스트
  Widget _buildCompleteMissions(double width) {
    return Obx(() {
      if (_controller.completeMyMissions.isEmpty) {
        return const SizedBox.shrink();
      }

      return _buildMissionListView(
        missions: _controller.completeMyMissions,
        width: width,
        itemBuilder:
            (mission, index) => _buildCompleteMissionItem(mission, width),
      );
    });
  }

  // 수락된 미션 리스트
  Widget _buildAcceptMissions(double width) {
    return Obx(() {
      if (_controller.acceptMyMissions.isEmpty) {
        return const SizedBox.shrink();
      }

      return _buildMissionListView(
        missions: _controller.acceptMyMissions,
        width: width,
        itemBuilder:
            (mission, index) => _buildAcceptMissionItem(mission, width),
      );
    });
  }

  // 대기중 미션 리스트
  Widget _buildPendingMissions(double width) {
    return Obx(() {
      if (_controller.pendingMyMissions.isEmpty) {
        return const SizedBox.shrink();
      }

      return _buildMissionListView(
        missions: _controller.pendingMyMissions,
        width: width,
        itemBuilder:
            (mission, index) => _buildPendingMissionItem(mission, width),
      );
    });
  }

  // 리스트로 만들어주는 함수
  Widget _buildMissionListView<T>({
    required List<T> missions,
    required double width,
    required Widget Function(T mission, int index) itemBuilder,
  }) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: missions.length,
      itemBuilder: (context, index) => itemBuilder(missions[index], index),
    );
  }

  // 완료된 미션 아이템
  Widget _buildCompleteMissionItem(MyMission mission, double screenWidth) {
    return GestureDetector(
      onTap: () => _toMissionGuessScreen(mission),
      child: _buildMissionContainer(
        screenWidth: screenWidth,
        child: SizedBox(
          height: screenWidth * 0.11,
          child: Row(
            children: [
              const Icon(Icons.check_circle_sharp, color: Colors.green),
              SizedBox(width: screenWidth * _itemSpacing),
              Text(
                "mission_screen.completed_mission_received",
                style: Get.textTheme.titleMedium,
              ).tr(),
            ],
          ),
        ),
      ),
    );
  }

  // 대기중 미션 아이템
  Widget _buildPendingMissionItem(MyMission mission, double screenWidth) {
    return _buildMissionContainer(
      screenWidth: screenWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMissionHeader(
            icon: const Icon(Icons.error_sharp, color: Colors.amber),
            status: mission.status,
            deadlineType: mission.deadlineType,
            targetDateTime: mission.acceptDeadline!,
            tooltipMessage: context.tr(
              "mission_screen.pending_mission_tooltip",
            ),
            screenWidth: screenWidth,
          ),
          SizedBox(height: screenWidth * _itemSpacing),
          _buildFriendsList(
            mission.friendsProfile,
            screenWidth,
            _pendingProfileSize,
          ),
        ],
      ),
    );
  }

  // 수락된 미션 아이템
  Widget _buildAcceptMissionItem(MyMission mission, double screenWidth) {
    return _buildMissionContainer(
      screenWidth: screenWidth,
      child: Column(
        children: [
          _buildMissionHeader(
            icon: const Icon(Icons.run_circle_sharp, color: Colors.deepOrange),
            status: mission.status,
            deadlineType: mission.deadlineType,
            targetDateTime: mission.deadline,
            tooltipMessage: context.tr("mission_screen.accept_mission_tooltip"),
            screenWidth: screenWidth,
          ),
          SizedBox(height: screenWidth * _itemSpacing),
          _buildFriendsList(
            mission.friendsProfile,
            screenWidth,
            _acceptProfileSize,
          ),
        ],
      ),
    );
  }

  // 미션 컨테이너
  Widget _buildMissionContainer({
    required double screenWidth,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: screenWidth * _verticalPadding,
        horizontal: screenWidth * _horizontalPadding,
      ),
      margin: EdgeInsets.only(
        left: screenWidth * _horizontalPadding,
        right: screenWidth * _horizontalPadding,
        bottom: screenWidth * _containerSpacing,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(screenWidth * _borderRadius),
      ),
      child: child,
    );
  }

  // 미션 헤더 Row
  Widget _buildMissionHeader({
    required Widget icon,
    required String status,
    required String deadlineType,
    required DateTime targetDateTime,
    required String tooltipMessage,
    required double screenWidth,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        icon,
        SizedBox(width: screenWidth * _itemSpacing),
        Text("mission_screen.$status", style: Get.textTheme.titleMedium).tr(),
        SizedBox(width: screenWidth * _smallSpacing),
        Text('(${context.tr("mission_screen.$deadlineType")}) '),
        _buildTooltip(tooltipMessage),
        const Spacer(),
        TimerWidget(
          targetDateTime: targetDateTime,
          fontSize: screenWidth * _timerFontSize,
          onTimerComplete: _controller.fetchMyMissions,
        ),
      ],
    );
  }

  // 툴팁
  Widget _buildTooltip(String message) {
    return Tooltip(
      showDuration: const Duration(days: 1),
      triggerMode: TooltipTriggerMode.tap,
      message: message,
      child: const Icon(Icons.help_outline_rounded, color: kGrey),
    );
  }

  // 친구 리스트
  Widget _buildFriendsList(
    List<dynamic> friendsProfile,
    double screenWidth,
    double profileSizeRatio,
  ) {
    return SizedBox(
      height: screenWidth * _friendsListHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder:
            (context, index) => SizedBox(width: screenWidth * _itemSpacing),
        itemCount: friendsProfile.length,
        itemBuilder: (context, index) {
          final friend = friendsProfile[index];
          return _buildFriendProfile(friend, screenWidth, profileSizeRatio);
        },
      ),
    );
  }

  // 친구 프로필
  Widget _buildFriendProfile(
    dynamic friend,
    double screenWidth,
    double profileSizeRatio,
  ) {
    return SizedBox(
      width: screenWidth * profileSizeRatio,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          profileImageOrDefault(
            friend.profileImageUrl,
            screenWidth * profileSizeRatio,
          ),
          Text(friend.nickname, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
