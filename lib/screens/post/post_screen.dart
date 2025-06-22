import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/controllers/post_controller.dart';
import 'package:manito/models/post.dart';
import 'package:manito/widgets/admob/banner_ad_widget.dart';
import 'package:manito/widgets/post/post_item.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> with WidgetsBindingObserver {
  late final PostController _controller;
  late final FriendsController _friendsController;

  // Constants
  static const double _horizontalPadding = 0.03;
  static const double _titleSpacing = 0.07;
  static const double _iconSize = 0.07;
  static const double _buttonPadding = 0.02;
  static const double _verticalSpacing = 0.02;
  static const double _borderRadius = 0.02;
  static const double _bannerPadding = 0.06;
  static const double _emptyStateHeight = 0.5;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<PostController>();
    _friendsController = Get.find<FriendsController>();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _controller.fetchPosts();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshPosts();
    }
  }

  // 새로고침
  Future<void> _refreshPosts() async {
    await _controller.fetchPosts();
  }

  // 본체
  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return Scaffold(
      appBar: _buildAppBar(width),
      body: SafeArea(child: _buildBody(width)),
    );
  }

  // 앱바
  AppBar _buildAppBar(double screenWidth) {
    return AppBar(
      centerTitle: false,
      titleSpacing: _titleSpacing * screenWidth,
      title: Text("post_screen.title", style: Get.textTheme.headlineLarge).tr(),
      actions: [_buildRefreshButton(screenWidth)],
    );
  }

  // 목록 새로고침 버튼
  Widget _buildRefreshButton(double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(right: _buttonPadding * screenWidth),
      child: IconButton(
        icon: Icon(Icons.refresh, size: _iconSize * screenWidth),
        onPressed: _refreshPosts,
      ),
    );
  }

  // 바디
  Widget _buildBody(double screenWidth) {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return _buildContent(screenWidth);
    });
  }

  // 바디 컬럼
  Widget _buildContent(double screenWidth) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildBannerAd(screenWidth),
          SizedBox(height: _verticalSpacing * screenWidth),
          _buildPostList(screenWidth),
        ],
      ),
    );
  }

  // 광고
  Widget _buildBannerAd(double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _horizontalPadding * screenWidth,
      ),
      child: BannerAdWidget(
        borderRadius: _borderRadius * screenWidth,
        width: Get.width - _bannerPadding * screenWidth,
        androidAdId: dotenv.env['BANNER_POST_ANDROID']!,
        iosAdId: dotenv.env['BANNER_POST_IOS']!,
      ),
    );
  }

  // 포스트 Obx
  Widget _buildPostList(double screenWidth) {
    return Obx(() {
      if (_controller.postList.isEmpty) {
        return Container(
          height: Get.height * _emptyStateHeight,
          alignment: Alignment.center,
          child:
              Text(
                "post_screen.exchange_missions_with_friends",
                style: Get.textTheme.bodySmall,
              ).tr(),
        );
      }

      return _buildPostListView(screenWidth);
    });
  }

  // 포스트 리스트뷰
  Widget _buildPostListView(double screenWidth) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _controller.postList.length,
      itemBuilder:
          (context, index) =>
              _buildPostItem(screenWidth, _controller.postList[index]),
    );
  }

  // 포스트 아이템
  Widget _buildPostItem(double screenWidth, Post post) {
    final manitoProfile = _friendsController.searchFriendProfile(
      post.manitoId!,
    );
    final creatorProfile = _friendsController.searchFriendProfile(
      post.creatorId!,
    );

    return PostItem(
      width: screenWidth,
      post: post,
      manitoProfile: manitoProfile,
      creatorProfile: creatorProfile,
    );
  }
}
