import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/controllers/mission_controller.dart';
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
    if (_controller.selectedFriends.length < 3) {
      Get.snackbar('알림', '최소 3명 이상의 친구를 선택해 주세요.');
    } else {
      // Get.dialog(
      //   AlertDialog(
      //     title: Text('미션 생성'),
      //     content: Text('미션을 생성하고 취소/수정 할 수 없습니다.'),
      //     actions: [
      //       TextButton(child: Text('취소'), onPressed: () => Get.back()),
      //       TextButton(
      //         child: Text('확인'),
      //         onPressed: () async {
      //           Get.back(); // 다이얼로그 닫기
      //           String result = await _controller.createMission(_selectedIndex);
      //           Get.snackbar('알림', result);
      //         },
      //       ),
      //     ],
      //   ),
      // );
      kDefaultDialog(
        '미션 생성',
        '미션을 생성하고 취소/수정 할 수 없습니다.',
        onYesPressed: () async {
          Get.back();
          String result = await _controller.createMission(_selectedIndex);
          Get.snackbar('알림', result);
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
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
        title: Text('미션 만들기', style: Get.textTheme.headlineMedium),
        actions: [
          TextButton(
            child: Text('확인', style: Get.textTheme.bodyMedium),
            onPressed: () => _showMissionCreationDialog(),
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
              Padding(
                padding: EdgeInsets.all(0.05 * width),
                child: Text('기간', style: Get.textTheme.titleLarge),
              ),
              // 기간 선택 토글 버튼
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: ToggleButtons(
                  borderRadius: BorderRadius.circular(0.01 * width),
                  constraints: BoxConstraints(
                    minHeight: 0.25 * width,
                    minWidth: (Get.width - 0.1 * width) / 2,
                  ),
                  isSelected: List.generate(
                    2,
                    (index) => index == _selectedIndex,
                  ),
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
              Divider(
                height: 0.15 * width,
                thickness: 0.03 * width,
                color: Colors.grey[300],
              ),
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
                  Container(
                    height: 0.25 * width,
                    alignment: Alignment.centerLeft,
                    child: Obx(() {
                      if (_controller.selectedFriends.isEmpty) {
                        return Center(child: Text('친구를 선택해 주세요'));
                      } else {
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          separatorBuilder:
                              (context, index) =>
                                  SizedBox(width: 0.0000 * width),
                          itemCount: _controller.selectedFriends.length,
                          itemBuilder: (context, index) {
                            final userProfile =
                                _controller.selectedFriends[index];
                            return InkWell(
                              onTap:
                                  () =>
                                      _controller.toggleSelection(userProfile),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 0.03 * width,
                                        ),
                                        child: profileImageOrDefault(
                                          userProfile.profileImageUrl!,
                                          0.16 * width,
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Icon(
                                          Icons.remove_circle_rounded,
                                          color: kGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(userProfile.nickname),
                                ],
                              ),
                            );
                          },
                        );
                      }
                    }),
                  ),

                  // 전체 친구 목록
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _friendsController.friendList.length,
                    itemBuilder: (context, index) {
                      final userProfile = _friendsController.friendList[index];
                      return Obx(() {
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 0.05 * width,
                            vertical: 0.01 * width,
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userProfile.nickname,
                                style: Get.textTheme.bodyMedium,
                              ),
                              Text(
                                userProfile.statusMessage,
                                style: Get.textTheme.labelMedium,
                              ),
                            ],
                          ),
                          visualDensity: const VisualDensity(vertical: 4),
                          leading: profileImageOrDefault(
                            userProfile.profileImageUrl!,
                            0.16 * width,
                          ),
                          trailing: Checkbox(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            value: _controller.isSelected(userProfile),
                            onChanged: (_) {
                              _controller.toggleSelection(userProfile);
                            },
                          ),
                          onTap: () {
                            _controller.toggleSelection(userProfile);
                          },
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
