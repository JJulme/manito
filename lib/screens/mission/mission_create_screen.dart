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
  final MissionCreateController _controller = Get.put(
    MissionCreateController(),
  );
  final FriendsController _friendsController = Get.find<FriendsController>();
  // 토글버튼
  int _selectedIndex = 0;

  /// 미션 생성 다이얼로그
  void _showMissionCreationDialog() {
    if (_controller.selectedFriends.length < 2) {
      customSnackbar(title: '알림', message: '최소 2명 이상의 친구를 선택해 주세요.');
    } else {
      kDefaultDialog(
        '미션 생성',
        '미션을 생성하고 취소/수정 할 수 없습니다.',
        onYesPressed: () async {
          String result = await _controller.createMission(_selectedIndex);
          customSnackbar(title: '알림', message: result);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0.02 * width,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
        title: Text('미션 만들기', style: Get.textTheme.headlineMedium),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 0.02 * width),
            child: TextButton(
              child: Text('확인', style: Get.textTheme.bodyMedium),
              onPressed: () => _showMissionCreationDialog(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 기간 텍스트
              _buildPeriodSection(width),
              Divider(),
              // 친구 선택/목록
              _buildFriendsSection(width),
            ],
          ),
        ),
      ),
    );
  }

  // 기간 선택 섹션
  Widget _buildPeriodSection(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 기간 텍스트
        Padding(
          padding: EdgeInsets.all(0.05 * width),
          child: Text('기간', style: Get.textTheme.titleLarge),
        ),
        // 기간 선택 토글 버튼
        Container(
          width: double.infinity,
          alignment: Alignment.center,
          child: ToggleButtons(
            fillColor: Colors.yellowAccent[300],
            selectedColor: Colors.yellowAccent[900],
            selectedBorderColor: Colors.yellowAccent[900],
            borderRadius: BorderRadius.circular(0.01 * width),
            constraints: BoxConstraints(
              minHeight: 0.25 * width,
              minWidth: (Get.width - 0.1 * width) / 2,
            ),
            isSelected: List.generate(2, (index) => index == _selectedIndex),
            onPressed: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [Text('1 Day'), Text('하루')],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [Text('1 Week'), Text('한주')],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 친구 선택 섹션
  Widget _buildFriendsSection(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 친구 텍스트
        Padding(
          padding: EdgeInsets.fromLTRB(
            0.05 * width,
            0,
            0.05 * width,
            0.05 * width,
          ),
          child: Text('친구', style: Get.textTheme.titleLarge),
        ),
        // 친구 선택/목록
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSelectedFriendsList(width),
            _buildAllFriendsList(width),
          ],
        ),
      ],
    );
  }

  // 선택된 친구 목록
  Widget _buildSelectedFriendsList(double width) {
    return Container(
      height: 0.25 * width,
      alignment: Alignment.centerLeft,
      child: Obx(() {
        if (_controller.selectedFriends.isEmpty) {
          return Center(child: Text('친구를 선택해 주세요'));
        }

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          separatorBuilder: (_, __) => SizedBox(width: 0),
          itemCount: _controller.selectedFriends.length,
          itemBuilder: (context, index) {
            final friendProfile = _controller.selectedFriends[index];
            return GestureDetector(
              onTap: () => _controller.toggleSelection(friendProfile),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0.03 * width),
                        child: profileImageOrDefault(
                          friendProfile.profileImageUrl!,
                          0.16 * width,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(Icons.remove_circle_rounded, color: kGrey),
                      ),
                    ],
                  ),
                  Text(friendProfile.nickname),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  // 전체 친구 목록
  Widget _buildAllFriendsList(double width) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _friendsController.friendList.length,
      itemBuilder: (context, index) {
        final friendProfile = _friendsController.friendList[index];

        return Obx(() {
          return ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 0.05 * width,
              vertical: 0.01 * width,
            ),
            title: Row(
              children: [
                profileImageOrDefault(
                  friendProfile.profileImageUrl,
                  0.16 * width,
                ),
                SizedBox(width: 0.02 * width),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friendProfile.nickname,
                        style: Get.textTheme.bodyMedium,
                      ),
                      Text(
                        friendProfile.statusMessage!,
                        style: Get.textTheme.labelMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            visualDensity: const VisualDensity(vertical: 4),
            trailing: Transform.scale(
              scale: 0.0028 * width,
              child: Checkbox(
                checkColor: Colors.black,
                fillColor: WidgetStateProperty.resolveWith<Color>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.yellowAccent[700]!;
                  }
                  return Colors.white;
                }),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                value: _controller.isSelected(friendProfile),
                onChanged: (_) => _controller.toggleSelection(friendProfile),
              ),
            ),
            onTap: () => _controller.toggleSelection(friendProfile),
          );
        });
      },
    );
  }
}
