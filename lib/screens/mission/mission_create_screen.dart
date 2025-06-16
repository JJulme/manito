import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/controllers/mission_controller.dart';
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
  late final FriendsController _friendsController;
  // 토글버튼
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(MissionCreateController());
    _friendsController = Get.find<FriendsController>();
  }

  /// 미션 생성 다이얼로그
  void _showMissionCreationDialog() {
    if (_controller.selectedFriends.length < 2) {
      customSnackbar(
        title: context.tr("mission_create_screen.snack_title"),
        message: context.tr("mission_create_screen.snack_message"),
      );
    } else {
      kDefaultDialog(
        context.tr("mission_create_screen.dialog_title"),
        context.tr("mission_create_screen.dialog_message"),
        onYesPressed: () async {
          String result = await _controller.createMission(_selectedIndex);
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

  // 본체
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
            _buildPeriodSection(screenWidth),
            Divider(),
            _buildFriendsSection(screenWidth),
          ],
        ),
      ),
    );
  }

  // 기간 선택
  Widget _buildPeriodSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: context.tr("mission_create_screen.period_section_title"),
          width: screenWidth,
        ),
        _PeriodToggleButtons(
          selectedIndex: _selectedIndex,
          onPeriodChanged: (index) => setState(() => _selectedIndex = index),
          screenWidth: screenWidth,
        ),
      ],
    );
  }

  // 친구 선택
  Widget _buildFriendsSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: context.tr("mission_create_screen.friends_section_title"),
          width: screenWidth,
        ),
        _SelectedFriendsList(controller: _controller, screenWidth: screenWidth),
        _AllFriendsList(
          controller: _controller,
          friendsController: _friendsController,
          screenWidth: screenWidth,
        ),
      ],
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

// 선택한 친구 리스트
class _SelectedFriendsList extends StatelessWidget {
  final MissionCreateController controller;
  final double screenWidth;

  const _SelectedFriendsList({
    required this.controller,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: screenWidth * 0.25,
      alignment: Alignment.centerLeft,
      child: Obx(() {
        if (controller.selectedFriends.isEmpty) {
          return Center(
            child: Text("mission_create_screen.empty_select_friends").tr(),
          );
        }

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          separatorBuilder: (_, __) => const SizedBox.shrink(),
          itemCount: controller.selectedFriends.length,
          itemBuilder: (context, index) {
            final friend = controller.selectedFriends[index];
            return _SelectedFriendItem(
              friend: friend,
              onTap: () => controller.toggleSelection(friend),
              screenWidth: screenWidth,
            );
          },
        );
      }),
    );
  }
}

// 선택한 친구 아이템
class _SelectedFriendItem extends StatelessWidget {
  final dynamic friend; // Replace with proper type
  final VoidCallback onTap;
  final double screenWidth;

  const _SelectedFriendItem({
    required this.friend,
    required this.onTap,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                child: profileImageOrDefault(
                  friend.profileImageUrl!,
                  screenWidth * 0.16,
                ),
              ),
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.remove_circle_rounded, color: kGrey),
              ),
            ],
          ),
          Text(friend.nickname),
        ],
      ),
    );
  }
}

// 전체 친구 리스트
class _AllFriendsList extends StatelessWidget {
  final MissionCreateController controller;
  final FriendsController friendsController;
  final double screenWidth;

  const _AllFriendsList({
    required this.controller,
    required this.friendsController,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: friendsController.friendList.length,
      itemBuilder: (context, index) {
        final friend = friendsController.friendList[index];
        return _FriendListItem(
          friend: friend,
          controller: controller,
          screenWidth: screenWidth,
        );
      },
    );
  }
}

// 친구 리스트 아이템
class _FriendListItem extends StatelessWidget {
  final dynamic friend; // Replace with proper type
  final MissionCreateController controller;
  final double screenWidth;

  const _FriendListItem({
    required this.friend,
    required this.controller,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenWidth * 0.01,
        ),
        title: _FriendInfo(friend: friend, screenWidth: screenWidth),
        visualDensity: const VisualDensity(vertical: 4),
        trailing: _FriendCheckbox(
          isSelected: controller.isSelected(friend),
          onChanged: (_) => controller.toggleSelection(friend),
          screenWidth: screenWidth,
        ),
        onTap: () => controller.toggleSelection(friend),
      );
    });
  }
}

// 친구 프로필 이미지, 이름, 상태메시지
class _FriendInfo extends StatelessWidget {
  final dynamic friend; // Replace with proper type
  final double screenWidth;

  const _FriendInfo({required this.friend, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        profileImageOrDefault(friend.profileImageUrl, screenWidth * 0.16),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(friend.nickname, style: Get.textTheme.bodyMedium),
              Text(
                friend.statusMessage ?? '',
                style: Get.textTheme.labelMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 체크박스
class _FriendCheckbox extends StatelessWidget {
  final bool isSelected;
  final ValueChanged<bool?> onChanged;
  final double screenWidth;

  const _FriendCheckbox({
    required this.isSelected,
    required this.onChanged,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: screenWidth * 0.0028,
      child: Checkbox(
        checkColor: Colors.black,
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.yellowAccent[700]!;
          }
          return Colors.white;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        value: isSelected,
        onChanged: onChanged,
      ),
    );
  }
}
