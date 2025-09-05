import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/mission_controller.dart';
import 'package:manito/models/user_profile.dart';
import 'package:manito/screens/mission/mission_friends_search_screen.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class MissionCreateScreen extends StatefulWidget {
  const MissionCreateScreen({super.key});

  @override
  State<MissionCreateScreen> createState() => _MissionCreateScreenState();
}

class _MissionCreateScreenState extends State<MissionCreateScreen> {
  // 컨트롤러 사용
  late final MissionCreateController _controller;
  // 토글버튼
  int _selectedType = 0;
  int _selectedPeriod = 0;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(MissionCreateController());
  }

  void _showMissionCreationDialog() {
    if (_controller.confirmedFriends.length < 2) {
      customSnackbar(
        title: context.tr("mission_create_screen.snack_title"),
        message: context.tr("mission_create_screen.snack_message"),
      );
    } else {
      kDefaultDialog(
        context.tr("mission_create_screen.dialog_title"),
        context.tr("mission_create_screen.dialog_message"),
        onYesPressed: () async {
          String result = await _controller.createMission(
            _selectedType,
            _selectedPeriod,
          );
          if (result == "create_mission_error") {
            if (!mounted) return;
            customSnackbar(
              title: context.tr("mission_create_screen.error_snack_title"),
              message: context.tr("mission_create_screen.error_snack_message"),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return Scaffold(appBar: _buildAppBar(width), body: _buildBody(width));
  }

  // 앱바
  AppBar _buildAppBar(double screenWidth) {
    return AppBar(
      centerTitle: false,
      titleSpacing: screenWidth * 0.02,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: Get.back,
      ),
      title:
          Text(
            "mission_create_screen.title",
            style: Get.textTheme.headlineMedium,
          ).tr(),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: screenWidth * 0.02),
          child: TextButton(
            onPressed: _showMissionCreationDialog,
            child:
                Text(
                  "mission_create_screen.done",
                  style: Get.textTheme.bodyMedium,
                ).tr(),
          ),
        ),
      ],
    );
  }

  // 바디
  Widget _buildBody(double screenWidth) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: "타입", width: screenWidth),
            _TypeToggleButtons(
              selectedIndex: _selectedType,
              onPeriodChanged: (index) => setState(() => _selectedType = index),
              screenWidth: screenWidth,
            ),
            Divider(),
            _SectionTitle(title: "기간", width: screenWidth),
            _PeriodToggleButtons(
              selectedIndex: _selectedPeriod,
              onPeriodChanged:
                  (index) => setState(() => _selectedPeriod = index),
              screenWidth: screenWidth,
            ),
            Divider(),
            _SectionTitle(title: "친구", width: screenWidth),
            _buildSelectedFriends(screenWidth),
          ],
        ),
      ),
    );
  }

  // 친구 선택, 선택 목록
  Widget _buildSelectedFriends(double screenWidth) {
    return InkWell(
      onTap: () {
        _controller.updateSelectedFriends();
        Get.to(() => MissionFriendsSearchScreen());
      },
      child: Obx(() {
        return _controller.confirmedFriends.isEmpty
            ? Container(
              width: double.infinity,
              height: screenWidth * 0.25,
              alignment: Alignment.center,
              child: Text("mission_create_screen.empty_select_friends").tr(),
            )
            : _buildFriendGridSection(screenWidth);
      }),
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
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 6 / 7,
          ),
          itemCount: _controller.confirmedFriends.length,
          itemBuilder: (context, index) {
            final friend = _controller.confirmedFriends[index];
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
}

// 타이틀 위젯
class _SectionTitle extends StatelessWidget {
  final String title;
  final double width;
  const _SectionTitle({required this.title, required this.width});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(width * 0.05),
      child: Text(title, style: Get.textTheme.titleLarge),
    );
  }
}

// 타입 토글 버튼
class _TypeToggleButtons extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onPeriodChanged;
  final double screenWidth;

  const _TypeToggleButtons({
    required this.selectedIndex,
    required this.onPeriodChanged,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: ToggleButtons(
        fillColor: Colors.yellowAccent[300],
        selectedColor: Colors.yellowAccent[900],
        selectedBorderColor: Colors.yellowAccent[900],
        borderRadius: BorderRadius.circular(screenWidth * 0.01),
        constraints: BoxConstraints(
          minHeight: screenWidth * 0.25,
          minWidth: (screenWidth - screenWidth * 0.1) / 3,
        ),
        isSelected: [
          selectedIndex == 0,
          selectedIndex == 1,
          selectedIndex == 2,
        ],
        onPressed: onPeriodChanged,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sunny),
              Text("일상", textAlign: TextAlign.center),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_rounded),
              Text("학교", textAlign: TextAlign.center),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.work),
              Text("직장", textAlign: TextAlign.center),
            ],
          ),
        ],
      ),
    );
  }
}

// 토글 버튼
class _PeriodToggleButtons extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onPeriodChanged;
  final double screenWidth;

  const _PeriodToggleButtons({
    required this.selectedIndex,
    required this.onPeriodChanged,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: ToggleButtons(
        fillColor: Colors.yellowAccent[300],
        selectedColor: Colors.yellowAccent[900],
        selectedBorderColor: Colors.yellowAccent[900],
        borderRadius: BorderRadius.circular(screenWidth * 0.01),
        constraints: BoxConstraints(
          minHeight: screenWidth * 0.25,
          minWidth: (screenWidth - screenWidth * 0.1) / 2,
        ),
        isSelected: [selectedIndex == 0, selectedIndex == 1],
        onPressed: onPeriodChanged,
        children: [
          Text(
            "mission_create_screen.toggle_btn_day",
            textAlign: TextAlign.center,
          ).tr(),
          Text(
            "mission_create_screen.toggle_btn_week",
            textAlign: TextAlign.center,
          ).tr(),
        ],
      ),
    );
  }
}
