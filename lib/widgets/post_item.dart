import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/features/badge/badge_provider.dart';
import 'package:manito/features/posts/post.dart';
import 'package:manito/features/profiles/profile.dart';
import 'package:manito/main.dart';
import 'package:manito/share/constants.dart';
import 'package:manito/share/custom_badge.dart';
import 'package:manito/widgets/profile_image_view.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostItem extends ConsumerWidget {
  final Post post;
  final FriendProfile manitoProfile;
  final FriendProfile creatorProfile;
  final int badgeCount;

  const PostItem({
    super.key,
    required this.post,
    required this.manitoProfile,
    required this.creatorProfile,
    required this.badgeCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 게시물 상세페이지 이동
    void toPostDetailScreen() {
      context.push(
        '/post_detail',
        extra: {
          'post': post,
          'manitoProfile': manitoProfile,
          'creatorProfile': creatorProfile,
        },
      );
      // 뱃지 제거
      ref
          .read(badgeProvider.notifier)
          .resetBadgeCount('post_comment', typeId: post.id!);
    }

    return InkWell(
      onTap: toPostDetailScreen,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 0.02 * width,
          horizontal: 0.04 * width,
        ),
        child: Row(
          children: [
            _buildProfileStack(manitoProfile, creatorProfile),

            SizedBox(width: 0.04 * width),

            // Mission Details
            Expanded(child: _buildMissionDetails(context, post)),

            // Timestamp and Badge
            _buildTimestampAndBadge(context, post),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStack(dynamic manito, dynamic creator) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '${manitoProfile.displayName} & ${creatorProfile.displayName}',
              style: Theme.of(context).textTheme.bodyMedium,
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
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimestampAndBadge(BuildContext context, Post post) {
    return SizedBox(
      width: width * 0.135,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            post.completeAt != null
                ? timeago.format(post.completeAt!, locale: 'en_short')
                : 'No Date',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          SizedBox(height: 0.02 * width),
          customBadgeIconWithLabel(badgeCount),
        ],
      ),
    );
  }
}
