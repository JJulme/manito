import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class FriendsRequestScreen extends StatefulWidget {
  const FriendsRequestScreen({super.key});

  @override
  State<FriendsRequestScreen> createState() => _FriendsRequestScreenState();
}

class _FriendsRequestScreenState extends State<FriendsRequestScreen> {
  final FriendsController friendsController = Get.find<FriendsController>();

  final FriendRequestController _controller = Get.put(
    FriendRequestController(),
  );

  /// 수락 함수
  Future<void> _acceptRequest(String senderId) async {
    String result = await _controller.acceptFriendRequest(senderId);
    // 요청 목록 다시 가져오기
    _controller.fetchFriendRequest();
    // 친구 목록 다시 가져오기
    friendsController.fetchFriendList();
    customSnackbar(title: '알림', message: result);
  }

  /// 거절 함수
  Future<void> _rejectRequest(String senderId) async {
    String result = await _controller.rejectFriendRequest(senderId);
    _controller.fetchFriendRequest();
    customSnackbar(title: '알림', message: result);
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
        title: Text('친구 요청 목록', style: Get.textTheme.headlineMedium),
      ),
      body: SafeArea(
        child: Obx(() {
          // 로딩중
          if (_controller.requestLoading.value) {
            return Center(child: CircularProgressIndicator());
          }
          // 요청 목록이 없는 경우
          else if (_controller.requestUserList.isEmpty) {
            return Center(
              child: Text('친구 요청이 없습니다.', style: Get.textTheme.bodyMedium),
            );
          }
          // 요청 목록이 있는 경우
          else {
            return ListView.builder(
              itemCount: _controller.requestUserList.length,
              itemBuilder: (context, index) {
                final userProfile = _controller.requestUserList[index];

                return Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 0.05 * width,
                        vertical: 0.03 * width,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // 프로필 이미지
                          profileImageOrDefault(
                            userProfile.profileImageUrl!,
                            0.2 * width,
                          ),
                          SizedBox(width: 0.05 * width),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 이름
                                Text(
                                  userProfile.nickname,
                                  style: Get.textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // 상태 메시지
                                Text(
                                  userProfile.statusMessage,
                                  style: Get.textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // 수락 버튼
                          IconButton(
                            icon: Icon(
                              Icons.check_rounded,
                              color: Colors.green,
                              size: 0.08 * width,
                            ),
                            onPressed: () => _acceptRequest(userProfile.id),
                          ),
                          // 거절 버튼
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: Colors.red,
                              size: 0.08 * width,
                            ),
                            onPressed: () => _rejectRequest(userProfile.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          }
        }),
      ),
    );
  }
}
