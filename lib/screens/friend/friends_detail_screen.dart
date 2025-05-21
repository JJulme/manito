import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/models/post.dart';
import 'package:manito/models/user_profile.dart';
import 'package:manito/screens/friend/friends_modify_screen.dart';
import 'package:manito/widgets/admob/banner_ad_widget.dart';
import 'package:manito/widgets/post/post_item.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class FriendsDetailScreen extends StatelessWidget {
  FriendsDetailScreen({super.key});
  final FriendsDetailCrontroller _controller = Get.put(
    FriendsDetailCrontroller(),
  );
  final FriendsController _friendsController = Get.find<FriendsController>();

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
        title: Text(_controller.friendProfile.nickname!),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 0.02 * width),
            child: PopupMenuButton(
              position: PopupMenuPosition.under,
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mode),
                          SizedBox(width: 0.02 * width),
                          Text('이름 수정', style: Get.textTheme.bodyMedium),
                        ],
                      ),
                      onTap: () => Get.to(() => FriendsModifyScreen()),
                    ),
                    // 친구 차단
                    PopupMenuItem(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.no_accounts_rounded),
                          SizedBox(width: 0.02 * width),
                          Text('친구 차단', style: Get.textTheme.bodyMedium),
                        ],
                      ),
                      onTap: () {
                        kDefaultDialog(
                          '친구 차단',
                          '친구를 차단하시겠습니까?',
                          onYesPressed: () async {
                            await _controller.blockFriend();
                            _friendsController.fetchFriendList();
                          },
                        );
                      },
                    ),
                  ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (_controller.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          } else {
            final FriendProfile friendProfile = _controller.friendProfile;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 이미지 등
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 0.04 * width),
                    child: Row(
                      children: [
                        // 프로필 이미지
                        profileImageOrDefault(
                          friendProfile.profileImageUrl,
                          0.25 * width,
                        ),
                        SizedBox(width: 0.04 * width),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_controller.manitoPostCount}'),
                                  Text('마니또'),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_controller.creatorPostCount}'),
                                  Text('만든 미션'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 0.02 * width),
                  // 상태 메시지
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 0.04 * width),
                    child: Text(friendProfile.statusMessage!, softWrap: true),
                  ),
                  SizedBox(height: 0.04 * width),
                  // 광고
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 0.04 * width),
                    child: BannerAdWidget(
                      borderRadius: 0.02 * width,
                      width: Get.width - 0.04 * width,
                      androidAdId: dotenv.env['BANNER_FRIEND_DETAIL_ANDROID']!,
                      iosAdId: dotenv.env['BANNER_FRIEND_DETAIL_IOS']!,
                    ),
                  ),
                  SizedBox(height: 0.04 * width),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 0.04 * width),
                    child: Text(
                      '${friendProfile.nickname} 님과 마니또',
                      style: Get.textTheme.titleMedium,
                    ),
                  ),
                  SizedBox(height: 0.02 * width),
                  // 친구와의 마니또 기록
                  Obx(() {
                    if (_controller.postList.isEmpty) {
                      return Container(
                        height: 0.6 * width,
                        alignment: Alignment.center,
                        child: Text('친구와 마니또 기록이 없습니다.'),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _controller.postList.length,
                      itemBuilder: (context, index) {
                        Post post = _controller.postList[index];
                        final manitoProfile = _friendsController
                            .searchFriendProfile(post.manitoId!);
                        final creatorProfile = _friendsController
                            .searchFriendProfile(post.creatorId!);
                        return PostItem(
                          width: width,
                          post: post,
                          manitoProfile: manitoProfile,
                          creatorProfile: creatorProfile,
                        );
                      },
                    );
                  }),
                ],
              ),
            );
          }
        }),
      ),
    );
  }
}
