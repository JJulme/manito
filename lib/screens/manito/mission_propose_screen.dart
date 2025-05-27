import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/manito_controller.dart';
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
  final MissionProposeController _controller = Get.put(
    MissionProposeController(),
  );
  final _rewardedAdManager = RewardedAdManager();

  @override
  void initState() {
    super.initState();
    _rewardedAdManager.loadRewardedAd(() => debugPrint('광고 로드 완료'));
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
      customSnackbar(title: '오류', message: '광고가 준비되지 않았습니다.\n잠시 후 다시 시도해주세요.');
    }
  }

  // 미션 수락 다이얼로그 표시
  void _showAcceptMissionDialog() {
    if (_controller.selectedContent.value == null) {
      customSnackbar(title: '알림', message: '미션을 선택해주세요.');
      return;
    }
    kDefaultDialog(
      '미션 수락',
      '미션을 수락하고 취소 할 수 없습니다.',
      onYesPressed: () async {
        String result = await _controller.acceptMissionPropose(
          _controller.selectedContent.value!,
        );
        customSnackbar(title: '알림', message: result);
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
  PreferredSizeWidget _buildAppBar(double width) {
    return AppBar(
      centerTitle: false,
      titleSpacing: 0.07 * width,
      automaticallyImplyLeading: false,
      title: Text(
        '${_controller.creatorProfile.nickname} 님 몰래 도움을 주세요!',
        style: Get.textTheme.headlineMedium,
        overflow: TextOverflow.ellipsis,
      ),
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
            child: Text('미션 선택', style: Get.textTheme.titleMedium),
          ),
          SizedBox(height: 0.03 * width),

          // 미션 선택 목록
          _buildMissionList(width, missionPropose),

          // 광고 버튼 (조건부 표시)
          if (GetPlatform.isAndroid && missionPropose.randomContents.length < 3)
            _buildAdButton(width),
        ],
      ),
    );
  }

  // 미션 설명 위젯
  Widget _buildMissionDescription(double width, profile, dynamic mission) {
    final DateFormat formatter = DateFormat('yy-MM-dd HH:mm');
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${profile.nickname} 에게', style: Get.textTheme.titleMedium),
          Text(
            '${mission.deadlineType} 내에  (${formatter.format(mission.deadline)})',
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
        final content = missionPropose.randomContents[index];
        return Obx(() => _buildMissionItem(width, content));
      },
    );
  }

  // 개별 미션 아이템 위젯
  Widget _buildMissionItem(double width, String content) {
    final isSelected = _controller.selectedContent.value == content;

    return GestureDetector(
      onTap: () => _controller.selectedContent.value = content,
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
            Text(
              content,
              style: TextStyle(
                fontSize: 0.05 * width,
                color: isSelected ? Colors.green : Colors.black87,
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
            Text(' 광고보고 +1', style: TextStyle(fontSize: 0.05 * width)),
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
