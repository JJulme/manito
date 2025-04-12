import 'package:flutter/material.dart';
import 'package:manito/models/post.dart';
import 'package:manito/models/user_profile.dart';
import 'package:manito/widgets/post/image_slider.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class PostDetail extends StatelessWidget {
  final double di;
  final UserProfile manitoProfile;
  final Post detailPost;
  final UserProfile creatorProfile;

  const PostDetail({
    super.key,
    required this.di,
    required this.manitoProfile,
    required this.detailPost,
    required this.creatorProfile,
  });

  /// 댓글창 열기
  // void _showCommentSheet(double di) {
  //   _controller.fetchComment();
  //   // 댓글 바텀 시트
  //   Get.bottomSheet(
  //     enableDrag: true,
  //     isScrollControlled: true,
  //     CommentSheet(
  //       di: di,
  //       controller: _controller,
  //       friendsController: friendsController,
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 마니또 프로필
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 0.02 * di),
          child: Row(
            children: [
              profileImageOrDefault(manitoProfile.profileImageUrl, 0.06 * di),
              SizedBox(width: 0.01 * di),
              Text(manitoProfile.nickname),
            ],
          ),
        ),
        SizedBox(height: 0.01 * di),

        // 미션 설명 이미지
        detailPost.imageUrlList!.isNotEmpty
            ? ImageSlider(
              images: detailPost.imageUrlList!,
              fit: BoxFit.contain,
              width: di,
            )
            : SizedBox.shrink(),

        // 설명 글
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 0.02 * di,
            vertical: 0.01 * di,
          ),
          child: Text(detailPost.description!),
        ),
        Divider(
          thickness: 0.02 * di,
          height: 0.06 * di,
          color: Colors.grey[200],
        ),

        // 크리에이터 프로필
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 0.02 * di),
          child: Row(
            children: [
              profileImageOrDefault(creatorProfile.profileImageUrl, 0.06 * di),
              SizedBox(width: 0.01 * di),
              Text(creatorProfile.nickname),
            ],
          ),
        ),
        SizedBox(height: 0.01 * di),

        // 추측 글
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 0.02 * di,
            vertical: 0.01 * di,
          ),
          child: Text(detailPost.guess!),
        ),

        // 버튼 모음
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 좋아요 버튼
            IconButton(
              icon: Icon(Icons.favorite_outline_rounded),
              onPressed: () {},
            ),
            // 댓글 버튼
            IconButton(
              icon: Icon(Icons.comment_outlined),
              onPressed: () {
                // showCommentSheet(di);
              },
            ),
          ],
        ),
        SizedBox(height: 0.01 * di),
      ],
    );
  }
}
