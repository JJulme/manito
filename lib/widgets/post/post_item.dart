import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/badge_controller.dart';
import 'package:manito/models/post.dart';
import 'package:manito/models/user_profile.dart';
import 'package:manito/screens/post/post_detail_screen.dart';
import 'package:manito/widgets/common/custom_badge.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class PostItem extends StatelessWidget {
  final dynamic post;
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
  final BadgeController _badgeController = Get.find<BadgeController>();

  // 게시물 상세 보기
  Future<void> _toPostDetailScreen(
    Post post,
    manitoProfile,
    creatorProfile,
  ) async {
    await Get.to(
      () => PostDetailScreen(),
      arguments: [post, manitoProfile, creatorProfile],
    );
  }

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
      onTap: () {
        _toPostDetailScreen(post, manitoProfile, creatorProfile);
        _badgeController.resetBadgeCount(post.id);
      },

      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 0.02 * width,
          horizontal: 0.04 * width,
        ),
        child: Row(
          children: [
            // Manito Profile
            _buildProfileColumn(manitoProfile, width),
            SizedBox(width: 0.02 * width),

            // Creator Profile
            _buildProfileColumn(creatorProfile, width),
            SizedBox(width: 0.04 * width),

            // Mission Details
            Expanded(child: _buildMissionDetails(post)),

            // Timestamp and Badge
            _buildTimestampAndBadge(post, _badgeController, width),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileColumn(dynamic profile, double width) {
    return SizedBox(
      width: 0.14 * width,
      child: Column(
        children: [
          profileImageOrDefault(profile?.profileImageUrl, 0.14 * width),
          SizedBox(height: 0.01 * width),
          Text(
            profile?.nickname ?? 'Unknown',
            overflow: TextOverflow.ellipsis,
            style: Get.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMissionDetails(dynamic post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.event, size: 0.05 * width),
            SizedBox(width: 0.01 * width),
            Text(
              post.deadlineType ?? 'No Type',
              style: Get.textTheme.bodySmall,
            ),
          ],
        ),
        SizedBox(height: 0.02 * width),
        Text(post.content ?? 'No Content', style: Get.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildTimestampAndBadge(
    dynamic post,
    BadgeController badgeController,
    double width,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(post.completeAt ?? 'No Date', style: Get.textTheme.labelMedium),
        SizedBox(height: 0.02 * width),
        Obx(() {
          return customBadgeIcon(
            badgeController.badgeComment[post.id] ?? 0.obs,
          );
        }),
      ],
    );
  }
}
