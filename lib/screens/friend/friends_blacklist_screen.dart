import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class FriendsBlacklistScreen extends StatefulWidget {
  const FriendsBlacklistScreen({super.key});

  @override
  State<FriendsBlacklistScreen> createState() => _FriendsBlacklistScreenState();
}

class _FriendsBlacklistScreenState extends State<FriendsBlacklistScreen> {
  // final FriendsController _controller = Get.find<FriendsController>();
  final BlacklistController _controller = Get.put(BlacklistController());

  Future<void> _unblackUser(String blackUserId) async {
    String result = await _controller.unblackUser(blackUserId);
    _controller.fetchBlacklist();
    Get.back();
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
        title: Text('차단 목록', style: Get.textTheme.headlineMedium),
      ),
      body: SafeArea(
        child: Obx(() {
          if (_controller.blacklistLoading.value) {
            return Center(child: CircularProgressIndicator());
          } else if (_controller.blackList.isEmpty) {
            return Center(child: Text('차단된 사용자가 없습니다.'));
          } else {
            return ListView.builder(
              itemCount: _controller.blackList.length,
              itemBuilder: (context, index) {
                final userProfile = _controller.blackList[index];
                return Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 0.04 * width,
                        vertical: 0.02 * width,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          profileImageOrDefault(
                            userProfile.profileImageUrl!,
                            0.2 * width,
                          ),
                          SizedBox(width: 0.04 * width),
                          Text(
                            userProfile.nickname,
                            style: Get.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Spacer(),
                          // 차단 해체
                          OutlinedButton(
                            child: Text('차단 해제'),
                            onPressed: () {
                              kDefaultDialog(
                                '차단 해제',
                                '차단을 해제하면 당신을 검색할 수 있습니다.',
                                onYesPressed:
                                    () => _unblackUser(userProfile.id),
                              );
                            },
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
