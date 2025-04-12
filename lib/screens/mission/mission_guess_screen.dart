import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/mission_controller.dart';
import 'package:manito/controllers/post_controller.dart';
import 'package:manito/models/user_profile.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class MissionGuessScreen extends StatelessWidget {
  MissionGuessScreen({super.key});

  final MissionGuessController _controller = Get.put(MissionGuessController());
  final PostController _postController = Get.find<PostController>();

  /// 미션 테이블에 추측글 업데이트
  void _updateMission() async {
    if (_controller.updateLoading.value) {
      return;
    } else if (_controller.descController.text.length < 5) {
      Get.snackbar('알림', '최소 5글자 이상 작성해주세요.');
    } else {
      String result = await _controller.updateMissionGuess();
      await _postController.fetchPosts();
      Get.snackbar('알림', result);
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: false,
          titleSpacing: 0.03 * width,
          title: Text('마니또 추리하기'),
          actions: [
            IconButton(
              padding: EdgeInsets.all(0),
              icon: Icon(Icons.close_rounded, size: 0.08 * width),
              onPressed: () => Get.back(result: false),
            ),
          ],
        ),
        body: SafeArea(
          child: Obx(() {
            if (_controller.isLoading.value) {
              return Center(child: CircularProgressIndicator());
            } else {
              return Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ~ 동안
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 0.04 * width,
                          ),
                          child: Text(
                            '${_controller.completeMission.deadlineType} 동안',
                            style: Get.textTheme.bodyLarge,
                          ),
                        ),
                        // ~ 까지
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 0.04 * width,
                          ),
                          child: Text(
                            '${_controller.completeMission.deadline} 까지',
                            style: Get.textTheme.bodyLarge,
                          ),
                        ),
                        SizedBox(height: 0.02 * width),
                        // 선택했던 친구 목록
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 0),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  // mainAxisSpacing: 0.01 * di,
                                  // crossAxisSpacing: 0.01 * di,
                                  childAspectRatio: 6 / 7, // 각 객체의 비율
                                ),
                            itemCount:
                                _controller
                                    .completeMission
                                    .friendsProfile
                                    .length,
                            itemBuilder: (context, index) {
                              UserProfile friendProfile =
                                  _controller
                                      .completeMission
                                      .friendsProfile[index];
                              return Container(
                                // color: Colors.amber,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    profileImageOrDefault(
                                      friendProfile.profileImageUrl,
                                      0.19 * width,
                                    ),
                                    SizedBox(height: 0.02 * width),
                                    Text(
                                      friendProfile.nickname,
                                      style: Get.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 0.04 * width),
                        // 추리 예상 작성
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 0.04 * width,
                          ),
                          child: TextField(
                            controller: _controller.descController,
                            minLines: 2,
                            maxLines: null,
                            maxLength: 999,
                            style: Get.textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: '나를 도와준 마니또가 누구일지 작성해주세요.',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 업로드 중 터치방지
                  !_controller.updateLoading.value
                      ? SizedBox.shrink()
                      : ModalBarrier(
                        dismissible: false,
                        color: Colors.black.withAlpha((0.5 * 255).round()),
                      ),
                ],
              );
            }
          }),
        ),
        // 마니또 확인하기 버튼
        bottomNavigationBar: BottomAppBar(
          padding: EdgeInsets.all(0),
          child: Container(
            height: 0.18 * width,
            margin: EdgeInsets.all(0.03 * width),
            child: ElevatedButton(
              onPressed: _updateMission,
              child:
                  _controller.updateLoading.value
                      ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                      : Text('마니또 확인하기', style: Get.textTheme.titleMedium),
            ),
          ),
        ),
      ),
    );
  }
}
