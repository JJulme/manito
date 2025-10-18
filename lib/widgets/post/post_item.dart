import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/arch_new/features/posts/post.dart';
import 'package:manito/controllers/badge_controller.dart';
import 'package:manito/widgets/common/custom_badge.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostItem extends StatelessWidget {
  final Post post;
  final dynamic manitoProfile;
  final dynamic creatorProfile;
  final double width;

  PostItem({
    super.key,
    required this.post,
    required this.manitoProfile,
    required this.creatorProfile,
    required this.width,
  });
  // final BadgeController _badgeController = Get.find<BadgeController>();

  // 게시물 상세 보기
  // Future<void> _toPostDetailScreen(
  //   Post post,
  //   manitoProfile,
  //   creatorProfile,
  // ) async {
  //   await Get.to(
  //     () => PostDetailScreen(),
  //     arguments: [post, manitoProfile, creatorProfile],
  //   );
  //   _badgeController.resetBadgeCount(post.id!);
  // }

  // /// 댓글창 열기
  // void _showCommentSheet(double w, String missionId) {
  //   // 댓글 바텀 시트
  //   Get.bottomSheet(
  //     enableDrag: true,
  //     isScrollControlled: true,
  //     CommentSheet(width: w, missionId: missionId),
  //   );
  // }

  // /// 채팅장 열기
  // void _showChatting(dynamic post) {
  //   Get.to(() => ChatScreen(), arguments: post);
  // }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // onTap: () => _toPostDetailScreen(post, manitoProfile, creatorProfile),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 0.02 * width,
          horizontal: 0.04 * width,
        ),
        child: Row(
          children: [
            _buildProfileStack(manitoProfile, creatorProfile, width),

            SizedBox(width: 0.04 * width),

            // Mission Details
            Expanded(child: _buildMissionDetails(context, post)),

            // Timestamp and Badge
            // _buildTimestampAndBadge(post, _badgeController, width),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStack(dynamic manito, dynamic creator, double width) {
    return SizedBox(
      height: width * 0.195,
      width: width * 0.195,
      child: Stack(
        children: [
          Positioned(
            left: width * 0.065,
            child: ProfileImageView(
              size: width * 0.13,
              profileImageUrl: manito.profileImageUrl,
            ),
          ),
          Positioned(
            top: width * 0.065,
            child: ProfileImageView(
              size: width * 0.13,
              profileImageUrl: creator.profileImageUrl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionDetails(BuildContext context, Post post) {
    final Map<String, IconData> iconMap = {
      'daily': (Icons.sunny),
      'school': (Icons.menu_book_rounded),
      'work': (Icons.work),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '${manitoProfile.nickname} & ${creatorProfile.nickname}',
              style: Get.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        SizedBox(height: 0.02 * width),
        Container(
          padding: EdgeInsets.symmetric(
            vertical: width * 0.015,
            horizontal: width * 0.04,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(50),
            // border: Border.all(color: Colors.black),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                iconMap[post.contentType],
                size: width * 0.05,
                color: Colors.grey[800],
              ),
              SizedBox(width: width * 0.01),
              Expanded(
                child: Text(
                  post.content!,
                  // style: Get.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimestampAndBadge(
    Post post,
    BadgeController badgeController,
    double width,
  ) {
    return SizedBox(
      width: width * 0.135,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            post.completeAt != null
                ? timeago.format(
                  post.completeAt!,
                  locale:
                      Get.context!.locale.languageCode == 'ko'
                          ? 'ko'
                          : 'en_short',
                )
                : 'No Date',
            style: Get.textTheme.labelMedium,
          ),
          SizedBox(height: 0.02 * width),
          Obx(() {
            return customBadgeIcon(
              badgeController.badgeComment[post.id] ?? 0.obs,
            );
          }),
        ],
      ),
    );
  }
}
