import 'package:easy_localization/easy_localization.dart';
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
  final BlacklistController _controller = Get.put(BlacklistController());
  // Constants for responsive design
  static const double _titleSpacingRatio = 0.02;
  static const double _horizontalPaddingRatio = 0.04;
  static const double _verticalPaddingRatio = 0.02;
  static const double _profileImageRatio = 0.2;
  static const double _spacingRatio = 0.04;

  // Dialog Methods
  void _showUnblockDialog(dynamic userProfile) {
    kDefaultDialog(
      context.tr("friends_blacklist_screen.dialog_title"),
      context.tr("friends_blacklist_screen.dialog_message"),
      onYesPressed: () => _unblackUser(userProfile.id),
    );
  }

  Future<void> _unblackUser(String blackUserId) async {
    String result = await _controller.unblackUser(blackUserId);
    _controller.fetchBlacklist();
    Get.back();
    if (!mounted) return;
    customSnackbar(
      title: context.tr('friends_blacklist_screen.snack_title'),
      message: context.tr('friends_blacklist_screen.$result'),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return Scaffold(
      appBar: _buildAppBar(width),
      body: SafeArea(child: _buildBody()),
    );
  }

  // 앱바
  PreferredSizeWidget _buildAppBar(double width) {
    return AppBar(
      centerTitle: false,
      titleSpacing: _titleSpacingRatio * width,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Get.back(),
      ),
      title:
          Text(
            'friends_blacklist_screen.title',
            style: Get.textTheme.headlineMedium,
          ).tr(),
    );
  }

  // 바디
  Widget _buildBody() {
    return Obx(() {
      if (_controller.blacklistLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_controller.blackList.isEmpty) {
        return Center(
          child:
              Text(
                'friends_blacklist_screen.empty_blacklist',
                style: Get.textTheme.bodyMedium,
              ).tr(),
        );
      }

      return _buildBlacklistView();
    });
  }

  // 차단 목록 리스트
  Widget _buildBlacklistView() {
    return ListView.builder(
      itemCount: _controller.blackList.length,
      itemBuilder: (context, index) {
        final userProfile = _controller.blackList[index];
        return _buildBlacklistItem(userProfile);
      },
    );
  }

  // 차단 유저 아이템
  Widget _buildBlacklistItem(dynamic userProfile) {
    final width = Get.width;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _horizontalPaddingRatio * width,
        vertical: _verticalPaddingRatio * width,
      ),
      child: Row(
        children: [
          _buildProfileImage(userProfile, width),
          SizedBox(width: _spacingRatio * width),
          _buildUserName(userProfile),
          const Spacer(),
          _buildUnblockButton(userProfile),
        ],
      ),
    );
  }

  // 차단 유저 프로필
  Widget _buildProfileImage(dynamic userProfile, double width) {
    return profileImageOrDefault(
      userProfile.profileImageUrl ?? '',
      _profileImageRatio * width,
    );
  }

  // 차단 유저 이름
  Widget _buildUserName(dynamic userProfile) {
    return Expanded(
      child: Text(
        userProfile.nickname ?? '',
        style: Get.textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // 차단 해제 버튼
  Widget _buildUnblockButton(dynamic userProfile) {
    return OutlinedButton(
      onPressed: () => _showUnblockDialog(userProfile),
      child: Text("friends_blacklist_screen.unblack_btn").tr(),
    );
  }
}
