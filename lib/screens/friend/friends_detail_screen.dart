import 'package:easy_localization/easy_localization.dart';
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

class FriendsDetailScreen extends StatefulWidget {
  const FriendsDetailScreen({super.key});

  @override
  State<FriendsDetailScreen> createState() => _FriendsDetailScreenState();
}

class _FriendsDetailScreenState extends State<FriendsDetailScreen> {
  late final FriendsDetailController _controller;
  late final FriendsController _friendsController;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(FriendsDetailController());
    _friendsController = Get.find<FriendsController>();
  }

  // 친구 이름 수정
  Future<void> _handleEditName() async {
    final result = await Get.to(
      () => FriendsModifyScreen(),
      arguments: _controller.friendProfile.id,
    );

    if (result == true) {
      _friendsController.fetchFriendList();
      Get.back();
    }
  }

  // 친구 차단 다이얼로그
  void _handleBlockFriend() {
    kDefaultDialog(
      context.tr("friends_detail_screen.dialog_title"),
      context.tr("friends_detail_screen.dialog_message"),
      onYesPressed: () async {
        await _controller.blockFriend();
        _friendsController.fetchFriendList();
      },
    );
  }

  // 본체
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Obx(
          () =>
              _controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBody(),
        ),
      ),
    );
  }

  // 앱바
  AppBar _buildAppBar() {
    return AppBar(
      centerTitle: false,
      titleSpacing: Get.width * 0.02,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Get.back(),
      ),
      title: Text(_controller.friendProfile.nickname),
      actions: [_buildPopupMenu()],
    );
  }

  // 팝업 메뉴
  Widget _buildPopupMenu() {
    return Padding(
      padding: EdgeInsets.only(right: Get.width * 0.02),
      child: PopupMenuButton(
        position: PopupMenuPosition.under,
        itemBuilder:
            (context) => [
              _buildEditNameMenuItem(),
              _buildBlockFriendMenuItem(),
            ],
      ),
    );
  }

  // 이름 수정 버튼
  PopupMenuItem _buildEditNameMenuItem() {
    return PopupMenuItem(
      onTap: _handleEditName,
      child: _buildMenuItemContent(
        icon: Icons.edit,
        text: context.tr("friends_detail_screen.modify_name"),
      ),
    );
  }

  // 차단 버튼
  PopupMenuItem _buildBlockFriendMenuItem() {
    return PopupMenuItem(
      onTap: _handleBlockFriend,
      child: _buildMenuItemContent(
        icon: Icons.no_accounts_rounded,
        text: context.tr("friends_detail_screen.block"),
      ),
    );
  }

  // 팝업 버튼 아이템
  Widget _buildMenuItemContent({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon),
        SizedBox(width: Get.width * 0.02),
        Text(text, style: Get.textTheme.bodyMedium),
      ],
    );
  }

  // 바디
  Widget _buildBody() {
    final friendProfile = _controller.friendProfile;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileSection(friendProfile),
          _buildStatusMessage(friendProfile),
          _buildAdSection(),
          _buildManitoHistorySection(friendProfile),
        ],
      ),
    );
  }

  // 프로필 이미지와 미션 기록
  Widget _buildProfileSection(FriendProfile friendProfile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Get.width * 0.04),
      child: Row(
        children: [
          profileImageOrDefault(
            friendProfile.profileImageUrl,
            Get.width * 0.25,
          ),
          SizedBox(width: Get.width * 0.04),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn(
                  count: _controller.creatorPostCount.value,
                  label: context.tr("friends_detail_screen.sent_missions"),
                ),
                _buildStatColumn(
                  count: _controller.manitoPostCount.value,
                  label: context.tr("friends_detail_screen.received_missions"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 보낸 미션, 받은 미션 횟수
  Widget _buildStatColumn({required int count, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text('$count'), Text(label)],
    );
  }

  // 상태 메시지
  Widget _buildStatusMessage(FriendProfile friendProfile) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Get.width * 0.04,
        Get.width * 0.02,
        Get.width * 0.04,
        Get.width * 0.04,
      ),
      child: Text(friendProfile.statusMessage ?? '', softWrap: true),
    );
  }

  // 광고
  Widget _buildAdSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Get.width * 0.04,
        0,
        Get.width * 0.04,
        Get.width * 0.04,
      ),
      child: BannerAdWidget(
        borderRadius: Get.width * 0.02,
        width: Get.width * 0.92,
        androidAdId: dotenv.env['BANNER_FRIEND_DETAIL_ANDROID']!,
        iosAdId: dotenv.env['BANNER_FRIEND_DETAIL_IOS']!,
      ),
    );
  }

  // 마니또 기록 위젯
  Widget _buildManitoHistorySection(FriendProfile friendProfile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Get.width * 0.04),
          child: Text(
            "friends_detail_screen.history",
            style: Get.textTheme.titleMedium,
          ).tr(namedArgs: {"nickname": friendProfile.nickname}),
        ),
        SizedBox(height: Get.width * 0.02),
        Obx(() => _buildPostList()),
      ],
    );
  }

  // 마니또 기록 리스트
  Widget _buildPostList() {
    if (_controller.postList.isEmpty) {
      return SizedBox(
        height: Get.width * 0.6,
        child: Center(
          child:
              Text(
                "friends_detail_screen.empty_history",
                style: Get.textTheme.bodyMedium,
              ).tr(),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _controller.postList.length,
      itemBuilder: (context, index) => _buildPostItem(index),
    );
  }

  // 마니또 기록 아이템
  Widget _buildPostItem(int index) {
    final Post post = _controller.postList[index];
    final manitoProfile = _friendsController.searchFriendProfile(
      post.manitoId!,
    );
    final creatorProfile = _friendsController.searchFriendProfile(
      post.creatorId!,
    );

    return PostItem(
      width: Get.width,
      post: post,
      manitoProfile: manitoProfile,
      creatorProfile: creatorProfile,
    );
  }
}
