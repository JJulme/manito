import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/badge_controller.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/controllers/mission_controller.dart';
import 'package:manito/screens/friend/friends_blacklist_screen.dart';
import 'package:manito/screens/friend/friends_detail_screen.dart';
import 'package:manito/screens/friend/friends_request_screen.dart';
import 'package:manito/screens/friend/friends_search_screen.dart';
import 'package:manito/screens/friend/profile_screen.dart';
import 'package:manito/screens/friend/setting_screen.dart';
import 'package:manito/widgets/admob/banner_ad_widget.dart';
import 'package:manito/widgets/common/custom_badge.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

// 위로 올려서 새로고침 기능 추가해야 함

class FriendsScreen extends StatelessWidget {
  FriendsScreen({super.key});
  final FriendsController _controller = Get.find<FriendsController>();
  final MissionController _missionController = Get.find<MissionController>();
  final BadgeController _badgeController = Get.find<BadgeController>();

  // 프로필 화면 이동
  void _toProfileScreen() {
    Get.to(() => ProfileScreen());
  }

  // 친구 상세 화면 이동
  void _toFriendDetail(dynamic friendProfile) {
    Get.to(() => FriendsDetailScreen(), arguments: friendProfile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(child: Obx(() => _buildBody())),
    );
  }

  // 앱바
  AppBar _buildAppBar() {
    final width = Get.width;
    return AppBar(
      centerTitle: false,
      titleSpacing: width * 0.07,
      title:
          Text('friends_screen.title', style: Get.textTheme.headlineLarge).tr(),
      actions: [
        PopupMenuButton<Widget>(
          icon: customBadgeIcon(
            _badgeController.badgeMap['friend_request']!,
            child: Icon(Icons.person_add_alt_1_rounded, size: width * 0.07),
          ),
          position: PopupMenuPosition.under,
          offset: Offset(width, 0),
          onSelected: (screen) => Get.to(() => screen),
          itemBuilder:
              (context) => [
                _buildPopupMenuItem(
                  value: FriendsSearchScreen(),
                  icon: Icons.person_add_alt_1_rounded,
                  text: context.tr('friends_screen.search'),
                  width: width,
                ),
                _buildPopupMenuItem(
                  value: FriendsRequestScreen(),
                  icon: Icons.supervisor_account_rounded,
                  text: context.tr('friends_screen.request'),
                  width: width,
                  onTap:
                      () => _badgeController.resetBadgeCount('friend_request'),
                  showBadge: true,
                ),
                _buildPopupMenuItem(
                  value: FriendsBlacklistScreen(),
                  icon: Icons.no_accounts_rounded,
                  text: context.tr('friends_screen.block'),
                  width: width,
                ),
              ],
        ),
        Padding(
          padding: EdgeInsets.only(right: width * 0.02),
          child: IconButton(
            icon: Icon(Icons.settings_rounded, size: width * 0.07),
            onPressed: () => Get.to(() => SettingScreen()),
          ),
        ),
      ],
    );
  }

  // 팝업 메뉴 공통 아이템 위젯
  PopupMenuItem<Widget> _buildPopupMenuItem({
    required Widget value,
    required IconData icon,
    required String text,
    required double width,
    VoidCallback? onTap,
    bool showBadge = false,
  }) {
    return PopupMenuItem<Widget>(
      value: value,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          showBadge
              ? customBadgeIcon(
                _badgeController.badgeMap['friend_request']!,
                child: Icon(icon),
              )
              : Icon(icon),
          SizedBox(width: width * 0.02),
          Text(text, style: Get.textTheme.bodyMedium),
        ],
      ),
    );
  }

  // 바디
  Widget _buildBody() {
    if (_controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    final width = Get.width;
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMyProfile(width),
          SizedBox(height: width * 0.03),
          _buildBannerAd(width),
          SizedBox(height: width * 0.03),
          _buildFriendsList(width),
          SizedBox(height: width * 0.03),
        ],
      ),
    );
  }

  // 내 프로필
  Widget _buildMyProfile(double width) {
    return InkWell(
      onTap: _toProfileScreen,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 0.03 * width,
          vertical: width * 0.02,
        ),
        child: Row(
          children: [
            // 프로필 이미지
            profileImageOrDefault(
              _controller.userProfile.value!.profileImageUrl,
              0.15 * width,
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
            _buildMissionBadge(
              _missionController.allMissions.length.toString(),
              width,
            ),
          ],
        ),
      ),
    );
  }

  // 광고
  Widget _buildBannerAd(double width) {
    return BannerAdWidget(
      width: Get.width - (width * 0.06),
      borderRadius: width * 0.02,
      androidAdId: dotenv.env['BANNER_FRIENDS_ANDROID']!,
      iosAdId: dotenv.env['BANNER_FRIENDS_IOS']!,
    );
  }

  // 친구 목록
  Widget _buildFriendsList(double width) {
    return Obx(() {
      if (_controller.friendList.isEmpty) {
        return Center(
          child:
              Text(
                'friends_screen.empty_friends',
                style: Get.textTheme.bodyMedium,
              ).tr(),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _controller.friendList.length,
        itemBuilder:
            (context, index) =>
                _buildFriendItem(_controller.friendList[index], width),
      );
    });
  }

  // 친구 항목
  Widget _buildFriendItem(dynamic friendProfile, double width) {
    return InkWell(
      onTap: () => _toFriendDetail(friendProfile),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.03,
          vertical: width * 0.02,
        ),
        child: Row(
          children: [
            profileImageOrDefault(friendProfile.profileImageUrl!, width * 0.15),
            SizedBox(width: width * 0.035),
            Expanded(child: _buildFriendInfo(friendProfile)),
            _buildMissionBadge(
              friendProfile.progressMissions.toString(),
              width,
            ),
          ],
        ),
      ),
    );
  }

  // 친구 프로필 사진, 이름, 상태메시지
  Widget _buildFriendInfo(dynamic friendProfile) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          friendProfile.nickname,
          style: Get.textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          friendProfile.statusMessage!,
          style: Get.textTheme.labelMedium,
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // 진행중인 미션 개수 아이콘
  Widget _buildMissionBadge(String count, double width) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        SvgPicture.asset(
          'assets/icons/star.svg',
          width: width * 0.08,
          color: count == '0' ? Colors.grey[400] : kYellow,
        ),
        Positioned(
          child: Text(
            count,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: width * 0.045),
          ),
        ),
      ],
    );
  }
}
