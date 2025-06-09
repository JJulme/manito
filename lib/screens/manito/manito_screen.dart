import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/controllers/manito_controller.dart';
import 'package:manito/models/mission.dart';
import 'package:manito/screens/manito/auto_reply_screen.dart';
import 'package:manito/screens/manito/manito_post_screen.dart';
import 'package:manito/screens/manito/mission_propose_screen.dart';
import 'package:manito/widgets/admob/banner_ad_widget.dart';
import 'package:manito/widgets/mission/custom_slide.dart';
import 'package:manito/widgets/mission/profile_mission.dart';
import 'package:manito/widgets/mission/timer.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class ManitoScreen extends StatefulWidget {
  const ManitoScreen({super.key});

  @override
  State<ManitoScreen> createState() => _ManitoScreenState();
}

class _ManitoScreenState extends State<ManitoScreen>
    with WidgetsBindingObserver {
  // Controllers
  late final ManitoController _controller;
  late final FriendsController _friendsController;

  // Constants
  static const double _horizontalPadding = 0.03;
  static const double _verticalSpacing = 0.03;
  static const double _borderRadius = 0.02;
  static const double _missionItemHeight = 0.22;
  static const double _iconSize = 0.07;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 컨트롤러 가져오는 모음 - initState()
  void _initializeControllers() {
    _controller = Get.find<ManitoController>();
    _friendsController = Get.find<FriendsController>();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshMissionData();
    }
  }

  // 데이터 새로고침 - didChangeAppLifecycleState, _toMissionProposeScreen
  Future<void> _refreshMissionData() async {
    _controller.isLoading.value = true;
    try {
      await Future.wait([
        _controller.fetchMissionProposeList(),
        _controller.fetchMissionAcceptList(),
        _controller.fetchMissionGuessList(),
      ]);
    } finally {
      _controller.isLoading.value = false;
    }
  }

  /// 자동응답 페이지 이동
  void _toAutoReplyScreen() {
    Get.to(() => AutoReplyScreen());
  }

  /// 미션 제안 상세 페이지 이동
  Future<void> _toMissionProposeScreen(String missionId, creatorProfile) async {
    final result = await Get.to(
      () => MissionProposeScreen(),
      arguments: [missionId, creatorProfile],
    );
    if (result == true) {
      await _refreshMissionData();
    }
  }

  /// 미션 게시물 작성 페이지 이동
  Future<void> _toMissionPostScreen(
    MissionAccept mission,
    creatorProfile,
  ) async {
    final result = await Get.to(
      () => ManitoPostScreen(),
      arguments: [mission, creatorProfile],
    );
    if (result == true) {
      await _controller.fetchMissionAcceptList();
      await _controller.fetchMissionGuessList();
    }
  }

  @override
  Widget build(BuildContext context) {
    // double width = Get.width;
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(child: Obx(() => _buildBody())),
    );
  }

  // 앱바
  PreferredSizeWidget _buildAppBar() {
    final width = Get.width;
    return AppBar(
      centerTitle: false,
      titleSpacing: _iconSize * width,
      title: Text('받은 미션', style: Get.textTheme.headlineLarge),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: _borderRadius * width),
          child: IconButton(
            icon: Icon(Icons.reply_rounded, size: _iconSize * width),
            onPressed: _toAutoReplyScreen,
          ),
        ),
      ],
    );
  }

  // 바디
  Widget _buildBody() {
    if (_controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildBannerAd(),
          SizedBox(height: _verticalSpacing * Get.width),

          _buildEmptyStateIfNeeded(),

          // 미션 제안 리스트
          _buildMissionList(
            missions: _controller.missionProposeList,
            itemBuilder: _buildMissionProposeItem,
          ),

          // 미션 추측 리스트
          _buildMissionList(
            missions: _controller.missionGuessList,
            itemBuilder: _buildMissionGuessItem,
          ),

          // 미션 수락 리스트
          _buildMissionList(
            missions: _controller.missionAcceptList,
            itemBuilder: _buildMissionAcceptItem,
          ),
        ],
      ),
    );
  }

  // 배너 광고
  Widget _buildBannerAd() {
    final width = Get.width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _horizontalPadding * width),
      child: BannerAdWidget(
        width: width - 0.06 * width,
        borderRadius: _borderRadius * width,
        androidAdId: dotenv.env['BANNER_MANITO_ANDROID']!,
        iosAdId: dotenv.env['BANNER_MANITO_IOS']!,
      ),
    );
  }

  // 받은 미션, 수락 미션이 없을 경우 처리
  Widget _buildEmptyStateIfNeeded() {
    return _controller.missionProposeList.isEmpty &&
            _controller.missionAcceptList.isEmpty &&
            _controller.missionGuessList.isEmpty
        ? Container(
          height: 0.5 * Get.height,
          width: double.infinity,
          alignment: Alignment.center,
          child: Text('진행중인 미션이 없습니다.', style: Get.textTheme.bodySmall),
        )
        : const SizedBox.shrink();
  }

  // 미션 제안과 수행중인 미션을 리스트로 만들어줌
  Widget _buildMissionList<T>({
    required List<T> missions,
    required Widget Function(T mission) itemBuilder,
  }) {
    return Obx(() {
      if (missions.isEmpty) return const SizedBox.shrink();

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: missions.length,
        itemBuilder: (context, index) => itemBuilder(missions[index]),
      );
    });
  }

  // 미션 제안 아이템
  Widget _buildMissionProposeItem(MissionProposeList missionPropose) {
    final width = Get.width;
    final creatorProfile = _friendsController.searchFriendProfile(
      missionPropose.creatorId,
    );
    return GestureDetector(
      onTap: () => _toMissionProposeScreen(missionPropose.id, creatorProfile),
      child: Container(
        height: _missionItemHeight * width,
        padding: EdgeInsets.all(_horizontalPadding * width),
        margin: EdgeInsets.only(
          left: _horizontalPadding * width,
          right: _horizontalPadding * width,
          bottom: _verticalSpacing * width,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(_borderRadius * width),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.red),
            Text(' 미션 도착 ', style: Get.textTheme.titleMedium),
            Tooltip(
              showDuration: const Duration(days: 1),
              triggerMode: TooltipTriggerMode.tap,
              message: '모든 미션은 선착순 1명',
              child: const Icon(Icons.help_outline_rounded, color: kGrey),
            ),
            const Spacer(),
            TimerWidget(
              targetDateTime: missionPropose.acceptDeadline,
              fontSize: _iconSize * width,
              onTimerComplete: () => _controller.fetchMissionProposeList(),
            ),
          ],
        ),
      ),
    );
  }

  // 미션 추측 아이템
  Widget _buildMissionGuessItem(MissionGuess missionGuess) {
    final width = Get.width;
    final creatorProfile = _friendsController.searchFriendProfile(
      missionGuess.creatorId,
    );
    return Container(
      height: _missionItemHeight * width,
      padding: EdgeInsets.all(_horizontalPadding * width),
      margin: EdgeInsets.only(
        left: _horizontalPadding * width,
        right: _horizontalPadding * width,
        bottom: _verticalSpacing * width,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(_borderRadius * width),
      ),
      child: Row(
        children: [
          profileImageOrDefault(creatorProfile.profileImageUrl, 0.14 * width),
          SizedBox(width: _borderRadius * width),
          Expanded(
            child: Text(
              "${creatorProfile.nickname} 마니또 추측중",
              style: Get.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  // 미션 수락 아이템
  Widget _buildMissionAcceptItem(MissionAccept missionAccept) {
    final width = Get.width;
    final creatorProfile = _friendsController.searchFriendProfile(
      missionAccept.creatorId,
    );
    return CustomSlide(
      mainWidget: _customSlideMainWidget(missionAccept, width),
      subWidget: _customSlideSubWidget(missionAccept, creatorProfile, width),
    );
  }

  // 커스텀 슬라이드 메인 위젯
  Widget _customSlideMainWidget(MissionAccept missionAccept, double width) {
    return Container(
      width: width - 0.06 * width,
      height: _missionItemHeight * width,
      padding: EdgeInsets.all(_horizontalPadding * width),
      margin: EdgeInsets.only(
        left: _horizontalPadding * width,
        right: _horizontalPadding * width,
        bottom: _verticalSpacing * width,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(_borderRadius * width),
      ),
      child: Row(
        children: [
          Icon(Icons.run_circle_sharp, color: Colors.amber[900]),
          Text(' 진행중 미션', style: Get.textTheme.titleMedium),
          const Spacer(),
          const Icon(Icons.timer_outlined),
          SizedBox(width: _borderRadius * width),
          TimerWidget(
            targetDateTime: missionAccept.deadline,
            fontSize: _iconSize * width,
            onTimerComplete: () => _controller.fetchMissionAcceptList(),
          ),
        ],
      ),
    );
  }

  // 커스텀 슬라이드 서브 위젯
  Widget _customSlideSubWidget(
    MissionAccept missionAccept,
    dynamic creatorProfile,
    double width,
  ) {
    return Container(
      width: width - 0.06 * width,
      height: _missionItemHeight * width,
      padding: EdgeInsets.all(_horizontalPadding * width),
      margin: EdgeInsets.only(
        left: _horizontalPadding * width,
        right: _horizontalPadding * width,
        bottom: _verticalSpacing * width,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(_borderRadius * width),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ProfileAndMission(
            creatorProfileUrl: creatorProfile.profileImageUrl!,
            size: 0.14 * width,
            creatorNickname: '${creatorProfile.nickname} 에게',
            content: missionAccept.content,
          ),
          IconButton(
            padding: const EdgeInsets.all(0),
            iconSize: 0.1 * width,
            icon: const Icon(Icons.edit_note),
            onPressed:
                () => _toMissionPostScreen(missionAccept, creatorProfile),
          ),
        ],
      ),
    );
  }
}
