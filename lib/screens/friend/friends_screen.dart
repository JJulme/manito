import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/badge_controller.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/screens/friend/friends_blacklist_screen.dart';
import 'package:manito/screens/friend/friends_detail_screen.dart';
import 'package:manito/screens/friend/friends_request_screen.dart';
import 'package:manito/screens/friend/friends_search_screen.dart';
import 'package:manito/screens/friend/modify_screen.dart';
import 'package:manito/screens/friend/setting_screen.dart';
import 'package:manito/widgets/admob/banner_ad_widget.dart';
import 'package:manito/widgets/common/custom_badge.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

// 위로 올려서 새로고침 기능 추가해야 함

class FriendsScreen extends StatelessWidget {
  FriendsScreen({super.key});
  final FriendsController _controller = Get.find<FriendsController>();
  final BadgeController _badgeContorller = Get.find<BadgeController>();

  /// 프로필 수정 화면 이동
  void _toProfileModifyScreen() async {
    // _controller.initModifyProfile();
    final result = await Get.to(
      () => ModifyScreen(),
      arguments: [
        _controller.userProfile.value?.profileImageUrl,
        _controller.userProfile.value?.nickname,
        _controller.userProfile.value?.statusMessage,
      ],
    );
    if (result == true) {
      _controller.isLoading.value = true;
      await _controller.getProfile();
      _controller.isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0.07 * width,
        title: Text(
          '친구',
          style: Get.textTheme.headlineLarge,
        ),
        actions: [
          PopupMenuButton(
            icon: badgeIcon(
              _badgeContorller.friendRequestBadge,
              Icon(
                Icons.person_add_alt_1_rounded,
                size: 0.07 * width,
              ),
            ),
            position: PopupMenuPosition.under,
            offset: Offset(width, 0),
            onSelected: (screen) {
              Get.to(() => screen);
            },
            itemBuilder: (context) => [
              // 친구 찾기
              PopupMenuItem(
                value: FriendsSearchScreen(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                    ),
                    SizedBox(width: 0.02 * width),
                    Text(
                      '친구 찾기',
                      style: Get.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              // 친구 요청
              PopupMenuItem(
                value: FriendsRequestScreen(),
                onTap: () => _badgeContorller.clearFriendRequest(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    badgeIcon(
                      _badgeContorller.friendRequestBadge,
                      Icon(
                        Icons.supervisor_account_rounded,
                      ),
                    ),
                    SizedBox(width: 0.02 * width),
                    Text(
                      '친구 요청',
                      style: Get.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              // 차단 목록
              PopupMenuItem(
                value: FriendsBlacklistScreen(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.no_accounts_rounded,
                    ),
                    SizedBox(width: 0.02 * width),
                    Text(
                      '차단 목록',
                      style: Get.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 설정 버튼
          IconButton(
            icon: Icon(
              Icons.settings_rounded,
              size: 0.07 * width,
            ),
            onPressed: () => Get.to(() => SettingScreen()),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(
          () {
            if (_controller.isLoading.value) {
              return Center(child: CircularProgressIndicator());
            } else {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // 내 프로필
                    myProfile(width),
                    SizedBox(height: 0.03 * width),
                    // 광고
                    BannerAdWidget(
                      width: Get.width - 0.06 * width,
                      borderRadius: 0.02 * width,
                      androidAdId: dotenv.env['BANNER_FRIENDS_ANDROID']!,
                      iosAdId: dotenv.env['BANNER_FRIENDS_IOS']!,
                    ),
                    SizedBox(height: 0.03 * width),
                    // 친구 목록
                    friendsList(width),
                    SizedBox(height: 0.03 * width),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  /// 내 프로필
  Padding myProfile(double width) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0.03 * width),
      child: Row(
        children: [
          // 프로필 이미지
          profileImageOrDefault(
            _controller.userProfile.value!.profileImageUrl,
            0.18 * width,
          ),
          SizedBox(width: 0.03 * width),
          // 이름, 상태 메시지
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _controller.userProfile.value!.nickname,
                  style: Get.textTheme.bodyMedium,
                ),
                Text(
                  _controller.userProfile.value!.statusMessage,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: Get.textTheme.labelMedium,
                ),
              ],
            ),
          ),
          SizedBox(width: 0.02 * width),
          // 프로필 수정 버튼
          SizedBox(
            height: 0.08 * width,
            width: 0.12 * width,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.all(0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                  side: BorderSide(color: kGrey),
                ),
              ),
              onPressed: _toProfileModifyScreen,
              child: Text(
                '수정',
                style: Get.textTheme.labelSmall,
              ),
            ),
          )
        ],
      ),
    );
  }

  /// 친구 목록
  Obx friendsList(double width) {
    return Obx(
      () {
        if (_controller.friendList.isEmpty) {
          return Center(
            child: Text(
              '친구를 추가해 보세요',
              style: Get.textTheme.bodyMedium,
            ),
          );
        } else {
          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _controller.friendList.length,
            itemBuilder: (context, index) {
              final userProfile = _controller.friendList[index];
              return InkWell(
                onTap: () {
                  Get.to(
                    () => FriendsDetailScreen(),
                    arguments: userProfile,
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 0.03 * width,
                    vertical: 0.02 * width,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // 프로필 이미지
                      profileImageOrDefault(
                        userProfile.profileImageUrl!,
                        0.18 * width,
                      ),
                      SizedBox(width: 0.035 * width),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 친구 이름
                            Text(
                              userProfile.nickname,
                              style: Get.textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // 친구 상태 메시지
                            Text(
                              userProfile.statusMessage,
                              style: Get.textTheme.labelMedium,
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}
