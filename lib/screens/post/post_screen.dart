import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/controllers/post_controller.dart';
import 'package:manito/models/post.dart';
import 'package:manito/models/user_profile.dart';
import 'package:manito/widgets/admob/banner_ad_widget.dart';
import 'package:manito/widgets/post/incomplete_item.dart';
import 'package:manito/widgets/post/post_item.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> with WidgetsBindingObserver {
  final PostController _controller = Get.find<PostController>();
  final FriendsController _friendsController = Get.find<FriendsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      _controller.isLoading.value = true;
      // _controller.fetchIncompletePost();
      _controller.fetchPosts();
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
        title: Text('게시물', style: Get.textTheme.headlineLarge),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 0.02 * width),
            child: IconButton(
              icon: Icon(Icons.refresh, size: 0.07 * width),
              onPressed: () async {
                _controller.isLoading.value = true;
                await _controller.fetchPosts();
                // await _controller.fetchIncompletePost();
                _controller.isLoading.value = false;
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (_controller.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                // 광고
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0.03 * width),
                  child: BannerAdWidget(
                    borderRadius: 0.02 * width,
                    width: Get.width - 0.06 * width,
                    androidAdId: dotenv.env['BANNER_POST_ANDROID']!,
                    iosAdId: dotenv.env['BANNER_POST_IOS']!,
                  ),
                ),
                SizedBox(height: 0.02 * width),
                // 미완성 게시물
                _incompletePostList(width),
                // 완성 게시물
                _postList(width),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// 추측이 안됀 게시물
  Obx _incompletePostList(double width) {
    return Obx(() {
      if (_controller.inCompletePostList.isEmpty) {
        return SizedBox.shrink();
      } else {
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _controller.inCompletePostList.length,
          itemBuilder: (context, index) {
            final String creatorId = _controller.inCompletePostList[index];
            UserProfile? creatorProfile = _friendsController
                .searchFriendProfile(creatorId);
            return IncompleteItem(
              width: width,
              creatorId: creatorId,
              creatorProfile: creatorProfile!,
            );
          },
        );
      }
    });
  }

  /// 완성된 게시물
  Obx _postList(double width) {
    return Obx(() {
      // 게시물이 없을 경우
      if (_controller.postList.isEmpty) {
        return Container(
          height: Get.height * 0.5,
          alignment: Alignment.center,
          child: Text('친구들과 미션을 주고 받아보세요!', style: Get.textTheme.bodySmall),
        );
      }
      // 게시물이 있을 경우
      else {
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _controller.postList.length,
          itemBuilder: (context, index) {
            Post post = _controller.postList[index];
            UserProfile? manitoProfile = _friendsController.searchFriendProfile(
              post.manitoId!,
            );
            UserProfile? creatorProfile = _friendsController
                .searchFriendProfile(post.creatorId!);
            return PostItem(
              width: width,
              post: post,
              manitoProfile: manitoProfile,
              creatorProfile: creatorProfile,
            );
          },
        );
      }
    });
  }
}
