import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/mission_controller.dart';
import 'package:manito/controllers/post_controller.dart';
import 'package:manito/models/user_profile.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class MissionGuessScreen extends StatelessWidget {
  MissionGuessScreen({super.key});

  final MissionGuessController _controller = Get.put(MissionGuessController());
  final PostController _postController = Get.find<PostController>();

  // Constants
  static const int _maxTextLength = 999;
  static const int _friendsGridColumns = 4;
  static const double _friendsAspectRatio = 6 / 7;

  /// 미션 테이블에 추측글 업데이트
  void _updateMission(BuildContext context) async {
    if (_controller.updateLoading.value) {
      return;
    } else if (_controller.descController.text.length < 5) {
      customSnackbar(
        title: context.tr("mission_guess_screen.text_short_snack_title"),
        message: context.tr("mission_guess_screen.text_short_snack_message"),
      );
    } else {
      String result = await _controller.updateMissionGuess();
      await _postController.fetchPosts();
      if (!context.mounted) return;
      customSnackbar(
        title: context.tr("mission_guess_screen.result_snack_title"),
        message: context.tr("mission_guess_screen.$result"),
      );
    }
  }

  // 본체
  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: _buildAppBar(width),
        body: _buildBody(context, width),
        // 마니또 확인하기 버튼
        bottomNavigationBar: _buildBottomButton(context, width),
      ),
    );
  }

  // 앱바
  AppBar _buildAppBar(double screenWidth) {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: screenWidth * 0.07,
      title: Text("mission_guess_screen.title").tr(),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: screenWidth * 0.02),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.close_rounded, size: screenWidth * 0.08),
            onPressed: () => Get.back(result: false),
          ),
        ),
      ],
    );
  }

  // 바디
  Widget _buildBody(BuildContext context, double screenWidth) {
    return SafeArea(
      child: Obx(() {
        return _controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : Stack(
              children: [
                _buildScrollableContent(context, screenWidth),
                _buildLoadingOverlay(),
              ],
            );
      }),
    );
  }

  // 스크롤 가능한 전체 내용
  Widget _buildScrollableContent(BuildContext context, double screenWidth) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDeadlineSection(context, screenWidth),
          _buildFriendGridSection(screenWidth),
          _buildGuessInput(context, screenWidth),
        ],
      ),
    );
  }

  // 로딩중에 화면 비활성화
  Widget _buildLoadingOverlay() {
    return Obx(() {
      return _controller.updateLoading.value
          ? ModalBarrier(
            dismissible: false,
            color: Colors.black.withAlpha((0.5 * 255).round()),
          )
          : const SizedBox.shrink();
    });
  }

  // 미션 기한
  Widget _buildDeadlineSection(BuildContext context, double screenWidth) {
    final String deadlineType = context.tr(
      "mission_guess_screen.${_controller.completeMission.deadlineType}",
    );
    final String deadline = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(_controller.completeMission.deadline);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(deadlineType, style: Get.textTheme.bodyLarge).tr(),
          Text(
            '$deadline ${context.tr("mission_guess_screen.until")}',
            style: Get.textTheme.bodyLarge,
          ),
          SizedBox(height: screenWidth * 0.02),
        ],
      ),
    );
  }

  // 친구들 프로필 그리드뷰
  Widget _buildFriendGridSection(double screenWidth) {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MissionGuessScreen._friendsGridColumns,
            childAspectRatio: MissionGuessScreen._friendsAspectRatio,
          ),
          itemCount: _controller.completeMission.friendsProfile.length,
          itemBuilder: (context, index) {
            final friend = _controller.completeMission.friendsProfile[index];
            return _buildFriendGridItem(friend, screenWidth);
          },
        ),
        SizedBox(height: screenWidth * 0.04),
      ],
    );
  }

  // 친구 프로필 그리드 아이템
  Widget _buildFriendGridItem(FriendProfile friend, double screenWidth) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          profileImageOrDefault(friend.profileImageUrl, screenWidth * 0.19),
          SizedBox(height: screenWidth * 0.02),
          Text(friend.nickname, style: Get.textTheme.bodyMedium),
        ],
      ),
    );
  }

  // 추측 글 작성 텍스트필드
  Widget _buildGuessInput(BuildContext context, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: TextField(
        controller: _controller.descController,
        minLines: 2,
        maxLines: null,
        maxLength: _maxTextLength,
        style: Get.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: context.tr("mission_guess_screen.hint_text"),
        ),
      ),
    );
  }

  // 바텀 버튼
  Widget _buildBottomButton(BuildContext context, double screenWidth) {
    return BottomAppBar(
      child: Container(
        margin: EdgeInsets.all(screenWidth * 0.03),
        child: ElevatedButton(
          onPressed: () => _updateMission(context),
          child: Obx(() {
            return _controller.updateLoading.value
                ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                : Text(
                  "mission_guess_screen.bottom_btn",
                  style: Get.textTheme.titleMedium,
                ).tr();
          }),
        ),
      ),
    );
  }
}
