import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/badge_controller.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/controllers/post_controller.dart';
import 'package:manito/custom_icons.dart';
import 'package:manito/models/post.dart';
import 'package:manito/models/user_profile.dart';
import 'package:manito/widgets/common/custom_badge.dart';
import 'package:manito/widgets/post/comment_sheet.dart';
import 'package:manito/widgets/post/image_slider.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class PostDetailScreen extends StatelessWidget {
  PostDetailScreen({super.key});

  final PostDetailController _controller = Get.put(PostDetailController());
  final FriendsController friendsController = Get.find<FriendsController>();
  final BadgeController _badgeController = Get.find<BadgeController>();

  /// 댓글창 열기
  void _showCommentSheet(double width, String missionId) {
    _badgeController.resetBadgeCount(missionId);
    // 댓글 바텀 시트
    Get.bottomSheet(
      enableDrag: true,
      isScrollControlled: true,
      CommentSheet(width: width, missionId: missionId),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Get.back(),
          ),
          title: Obx(() {
            if (_controller.isLoading.value) {
              return SizedBox.shrink();
            } else {
              return Text(
                '${_controller.post.deadlineType} / ${_controller.post.content}',
                style: Get.textTheme.headlineSmall,
              );
            }
          }),
        ),
        body: SafeArea(
          child: Obx(() {
            if (_controller.isLoading.value) {
              return Center(child: CircularProgressIndicator());
            } else {
              // Post post = _controller.posts;
              Post detailPost = _controller.detailPost.value!;
              UserProfile manitoProfile = _controller.manitoProfile;
              UserProfile? creatorProfile = _controller.creatorProfile;
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 마니또 프로필
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
                      // 마니또
                      child: Row(
                        children: [
                          profileImageOrDefault(
                            manitoProfile.profileImageUrl,
                            0.15 * width,
                          ),
                          SizedBox(width: 0.03 * width),
                          Text(manitoProfile.nickname),
                        ],
                      ),
                    ),
                    SizedBox(height: 0.03 * width),
                    // 미션 설명 이미지
                    detailPost.imageUrlList!.isNotEmpty
                        ? ImageSlider(
                          images: detailPost.imageUrlList!,
                          width: width,
                          boxFit: BoxFit.contain,
                        )
                        : SizedBox.shrink(),
                    // 설명 글
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 0.05 * width,
                        vertical: 0.02 * width,
                      ),
                      child: Text(detailPost.description!),
                    ),
                    Divider(),

                    // 마니또 프로필
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
                      // 마니또
                      child: Row(
                        children: [
                          profileImageOrDefault(
                            creatorProfile.profileImageUrl,
                            0.15 * width,
                          ),
                          SizedBox(width: 0.03 * width),
                          Text(creatorProfile.nickname),
                        ],
                      ),
                    ),
                    SizedBox(height: 0.03 * width),
                    // 추측 글
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 0.05 * width,
                        vertical: 0.03 * width,
                      ),
                      child: Text(detailPost.guess!),
                    ),
                    // 버튼 모음
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // // 좋아요 버튼
                          // IconButton(
                          //   icon: Icon(Icons.favorite_outline_rounded),
                          //   onPressed: () {},
                          // ),
                          //  댓글 버튼
                          IconButton(
                            padding: EdgeInsets.all(0),
                            onPressed:
                                () => _showCommentSheet(width, detailPost.id!),
                            icon: customBadgeIcon(
                              _badgeController.badgeComment[detailPost.id] ??
                                  0.obs,
                              Icon(CustomIcons.comment_empty),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 0.03 * width),
                  ],
                ),
              );
            }
          }),
        ),
      ),
    );
  }
}
