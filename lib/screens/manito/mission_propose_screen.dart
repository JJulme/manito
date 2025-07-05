import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/manito_controller.dart';
import 'package:manito/models/mission.dart';
import 'package:manito/widgets/admob/rewarded_ad_manager.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:manito/widgets/mission/timer.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class MissionProposeScreen extends StatefulWidget {
  const MissionProposeScreen({super.key});

  @override
  State<MissionProposeScreen> createState() => _MissionProposeScreenState();
}

class _MissionProposeScreenState extends State<MissionProposeScreen> {
  late MissionProposeController _controller;
  final _rewardedAdManager = RewardedAdManager();

  @override
  void initState() {
    super.initState();
    _controller = Get.put(MissionProposeController());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final String result = await _controller.fetchMissionPropose();
      if (!mounted) return;
      final String snackTitle;
      final String snackMessage;
      if (result == 'success') {
        return;
      } else if (result == 'PGRST116') {
        snackTitle = context.tr("mission_propose_screen.late_snack_title");
        snackMessage = context.tr("mission_propose_screen.late_snack_message");
      } else {
        snackTitle = context.tr("mission_propose_screen.error_snack_title");
        snackMessage = context.tr("mission_propose_screen.error_snack_message");
      }
      customSnackbar(title: snackTitle, message: snackMessage);
      _rewardedAdManager.loadRewardedAd(() => debugPrint('광고 로드 완료'));
    });
  }

  @override
  void dispose() {
    _rewardedAdManager.disposeRewardedAd();
    super.dispose();
  }

  // 광고 보기 동작 처리
  void _showRewardedAd() {
    if (_rewardedAdManager.isRewardedAdReady) {
      _rewardedAdManager.showRewardedAd(() async {
        debugPrint('광고 시청 완료');
        await _controller.addRandomMissionContent();
        await _controller.fetchMissionPropose();
      });
    } else {
      customSnackbar(
        title: context.tr("mission_propose_screen.ad_snack_title"),
        message: context.tr("mission_propose_screen.ad_snack_message"),
      );
    }
  }

  // 미션 수락 다이얼로그 표시
  void _showAcceptMissionDialog() {
    if (_controller.selectedContentId.value == null) {
      customSnackbar(
        title: context.tr("mission_propose_screen.select_snack_title"),
        message: context.tr("mission_propose_screen.select_snack_message"),
      );
      return;
    }
    kDefaultDialog(
      context.tr("mission_propose_screen.dialog_title"),
      context.tr("mission_propose_screen.dialog_message"),
      onYesPressed: () async {
        String result = await _controller.acceptMissionPropose(
          _controller.selectedContentId.value!,
        );
        if (!mounted) return;
        customSnackbar(
          title: context.tr("mission_propose_screen.snack_title"),
          message: context.tr("mission_propose_screen.$result"),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = Get.width;
    return Scaffold(
      appBar: _buildAppBar(width),
      body: SafeArea(
        child: Obx(
          () =>
              _controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(width),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(width),
    );
  }

  // 앱바 위젯
  AppBar _buildAppBar(double width) {
    return AppBar(
      centerTitle: false,
      titleSpacing: 0.07 * width,
      automaticallyImplyLeading: false,
      title: Text(
        "mission_propose_screen.title",
        style: Get.textTheme.headlineMedium,
        overflow: TextOverflow.ellipsis,
      ).tr(namedArgs: {"nickname": _controller.creatorProfile.nickname}),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 0.02 * width),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.close_rounded, size: 0.07 * width),
            onPressed: () => Get.back(result: false),
          ),
        ),
      ],
    );
  }

  // 화면 본문 위젯
  Widget _buildContent(double width) {
    final creatorProfile = _controller.creatorProfile;
    final missionPropose = _controller.missionPropose.value;

    if (missionPropose == null) {
      return const Center(child: Text('미션 정보를 불러올 수 없습니다.'));
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 프로필 이미지
          SizedBox(height: 0.03 * width),
          profileImageOrDefault(creatorProfile.profileImageUrl!, 0.3 * width),
          SizedBox(height: 0.03 * width),

          // 미션 설명
          _buildMissionDescription(width, creatorProfile, missionPropose),
          SizedBox(height: 0.03 * width),

          // 미션 선택 타이틀
          Container(
            padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
            alignment: Alignment.centerLeft,
            child:
                Text(
                  "mission_propose_screen.select_mission",
                  style: Get.textTheme.titleMedium,
                ).tr(),
          ),
          SizedBox(height: 0.03 * width),

          // 미션 선택 목록
          _buildMissionList(width, missionPropose),

          // 광고 버튼 (조건부 표시)
          if (missionPropose.randomContents.length < 3) _buildAdButton(width),
        ],
      ),
    );
  }

  // 미션 설명 위젯
  Widget _buildMissionDescription(double width, profile, dynamic mission) {
    final DateFormat formatter = DateFormat('yy-MM-dd HH:mm');
    final String deadlineType = context.tr(
      "mission_propose_screen.${mission.deadlineType}",
    );
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "mission_propose_screen.for_friend",
            style: Get.textTheme.titleMedium,
          ).tr(namedArgs: {"nickname": profile.nickname}),
          Text(
            '${context.tr(deadlineType)} (${formatter.format(mission.deadline)})',
            style: Get.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  // 미션 선택 목록 위젯
  Widget _buildMissionList(double width, dynamic missionPropose) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: missionPropose.randomContents.length,
      itemBuilder: (context, index) {
        final MissionContent missionContent =
            missionPropose.randomContents[index];
        return Obx(() => _buildMissionItem(width, missionContent));
      },
    );
  }

  // 개별 미션 아이템 위젯
  Widget _buildMissionItem(double width, MissionContent missionContent) {
    final isSelected = _controller.selectedContentId.value == missionContent.id;

    return GestureDetector(
      onTap: () => _controller.selectedContentId.value = missionContent.id,

      child: Container(
        height: 0.15 * width,
        margin: EdgeInsets.symmetric(
          horizontal: 0.05 * width,
          vertical: 0.015 * width,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 0.05 * width,
          vertical: 0.015 * width,
        ),
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(0.02 * width),
          border: Border.all(color: isSelected ? Colors.green : Colors.grey),
        ),
        child: Row(
          children: [
            Icon(
              Icons.arrow_right_rounded,
              size: 0.12 * width,
              color: isSelected ? Colors.green : Colors.white70,
            ),
            SizedBox(width: 0.03 * width),
            Expanded(
              child: AutoSizeText(
                missionContent.content,
                minFontSize: 10,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 0.05 * width,
                  color: isSelected ? Colors.green : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 광고 버튼 위젯
  Widget _buildAdButton(double width) {
    return Container(
      width: double.infinity,
      height: 0.15 * width,
      margin: EdgeInsets.symmetric(
        horizontal: 0.05 * width,
        vertical: 0.015 * width,
      ),
      child: OutlinedButton(
        onPressed: _showRewardedAd,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_creation_outlined, size: 0.07 * width),
            Text(
              "mission_propose_screen.watch_ad",
              style: TextStyle(fontSize: 0.05 * width),
            ).tr(),
          ],
        ),
      ),
    );
  }

  // 하단 바 위젯
  Widget _buildBottomBar(double width) {
    return BottomAppBar(
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.all(0.03 * width),
        child: ElevatedButton(
          onPressed: _showAcceptMissionDialog,
          child: Obx(() {
            if (_controller.missionPropose.value == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('수락하기 ', style: Get.textTheme.titleLarge),
                TimerWidget(
                  targetDateTime:
                      _controller.missionPropose.value!.acceptDeadline,
                  fontSize: 0.07 * width,
                  color: Colors.black,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
