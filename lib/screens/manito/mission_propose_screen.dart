import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/manito_controller.dart';
import 'package:manito/models/user_profile.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:manito/widgets/mission/timer.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class MissionProposeScreen extends StatelessWidget {
  MissionProposeScreen({super.key});

  final MissionProposeController _controller = Get.put(
    MissionProposeController(),
  );

  /// 미션 수락 함수
  void _showAcceptMissionDialog() async {
    if (_controller.selectedContent.value == null) {
      customSnackbar(title: '알림', message: '미션을 선택해주세요.');
    } else {
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
  }

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return Scaffold(
      appBar: AppBar(
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
              padding: EdgeInsets.all(0),
              icon: Icon(Icons.close_rounded, size: 0.07 * width),
              onPressed: () => Get.back(result: false),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (_controller.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          } else {
            final UserProfile creatorProfile = _controller.creatorProfile;
            final missionPropose = _controller.missionPropose.value;
            return SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 프로필 이미지
                  SizedBox(height: 0.03 * width),
                  profileImageOrDefault(
                    creatorProfile.profileImageUrl!,
                    0.3 * width,
                  ),
                  SizedBox(height: 0.03 * width),
                  // 설명
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
                    alignment: Alignment.center,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${creatorProfile.nickname} 에게',
                          style: Get.textTheme.titleMedium,
                        ),
                        Text(
                          '${missionPropose!.deadlineType} 내에  (${missionPropose.deadline})',
                          style: Get.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 0.03 * width),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
                    alignment: Alignment.centerLeft,
                    child: Text('미션 선택', style: Get.textTheme.titleMedium),
                  ),
                  SizedBox(height: 0.03 * width),
                  // 미션 버튼 목록
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: missionPropose.randomContents.length,
                    itemBuilder: (context, index) {
                      final content = missionPropose.randomContents[index];
                      return Obx(() {
                        return GestureDetector(
                          onTap: () {
                            _controller.selectedContent.value = content;
                          },
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
                              border: Border.all(
                                color:
                                    _controller.selectedContent.value == content
                                        ? Colors.green
                                        : Colors.grey,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_right_rounded,
                                  size: 0.12 * width,
                                  color:
                                      _controller.selectedContent.value ==
                                              content
                                          ? Colors.green
                                          : Colors.white70,
                                ),
                                SizedBox(width: 0.03 * width),
                                Text(
                                  content,
                                  style: TextStyle(
                                    fontSize: 0.05 * width,
                                    color:
                                        _controller.selectedContent.value ==
                                                content
                                            ? Colors.green
                                            : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      });
                    },
                  ),
                  // // 광고 버튼
                  // Container(
                  //   width: double.infinity,
                  //   height: 0.15 * width,
                  //   margin: EdgeInsets.symmetric(
                  //     horizontal: 0.05 * width,
                  //     vertical: 0.015 * width,
                  //   ),
                  //   child: OutlinedButton(
                  //     // style: ElevatedButton.styleFrom(
                  //     //   backgroundColor: Colors.lime,
                  //     // ),
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         Icon(Icons.movie_creation_outlined, size: 0.07 * width),
                  //         Text(
                  //           ' 광고보고 +1',
                  //           style: TextStyle(fontSize: 0.05 * width),
                  //         ),
                  //       ],
                  //     ),
                  //     onPressed: () {
                  //       Get.snackbar('알림', '광고 구현하기');
                  //     },
                  //   ),
                  // ),
                ],
              ),
            );
          }
        }),
      ),
      // 수락하기 버튼
      bottomNavigationBar: BottomAppBar(
        height: 0.18 * width,
        padding: EdgeInsets.all(0),
        child: Container(
          width: double.infinity,
          height: 0.18 * width,
          margin: EdgeInsets.symmetric(
            horizontal: 0.05 * width,
            vertical: 0.03 * width,
          ),
          child: ElevatedButton(
            onPressed: () => _showAcceptMissionDialog(),
            child: Obx(() {
              if (_controller.missionPropose.value == null) {
                return Center(child: CircularProgressIndicator());
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('수락하기 ', style: Get.textTheme.titleLarge),
                    TimerWidget(
                      targetDateTimeString:
                          _controller.missionPropose.value!.acceptDeadline,
                      fontSize: 0.07 * width,
                      color: Colors.black,
                      // onTimerComplete: () {
                      //   Get.back(result: true);
                      //   Get.snackbar('미션 수락 불가', '미션을 수락 할 수 없습니다.');
                      // },
                    ),
                  ],
                );
              }
            }),
          ),
        ),
      ),
    );
  }
}
