import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/controllers/post_controller.dart';
import 'package:manito/custom_icons.dart';
import 'package:manito/models/comment.dart';
import 'package:manito/models/post.dart';
import 'package:manito/widgets/post/image_slider.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostDetailScreen extends StatelessWidget {
  PostDetailScreen({super.key});

  final PostDetailController _controller = Get.put(PostDetailController());
  final FriendsController friendsController = Get.find<FriendsController>();

  /// 댓글 공백 입력 방지
  void _handleSendComment() {
    if (_controller.commentController.text.trim().isNotEmpty) {
      _controller.insertComment();
      _controller.commentController.clear();
    }
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
          child: Column(
            children: [
              // 미션, 추측, 댓글 화면
              Expanded(
                child: Obx(() {
                  if (_controller.isLoading.value) {
                    return Center(child: CircularProgressIndicator());
                  } else {
                    Post detailPost = _controller.detailPost.value!;
                    final manitoProfile = _controller.manitoProfile;
                    final creatorProfile = _controller.creatorProfile;
                    return SingleChildScrollView(
                      controller: _controller.commentScrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 마니또 작성글
                          _PostHeader(
                            width: width,
                            detailPost: detailPost,
                            manitoProfile: manitoProfile,
                          ),
                          Divider(),
                          // 생성자 추측글
                          _GuessSection(
                            width: width,
                            detailPost: detailPost,
                            creatorProfile: creatorProfile,
                          ),
                          Divider(),
                          // 댓글창
                          Obx(() {
                            if (_controller.commentLoading.value) {
                              return Center(child: CircularProgressIndicator());
                            } else {
                              return _CommentList(
                                width: width,
                                comments: _controller.commentList,
                                friendsController: friendsController,
                              );
                            }
                          }),
                          SizedBox(height: 0.05 * width),
                        ],
                      ),
                    );
                  }
                }),
              ),
              // 채팅 입력창
              _MessageBar(
                messageTextController: _controller.commentController,
                onSendPressed: _handleSendComment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 마니또의 미션 내용
class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.width,
    required this.detailPost,
    required this.manitoProfile,
  });

  final double width;
  final Post detailPost;
  final manitoProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 마니또 프로필
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
          child: Row(
            children: [
              profileImageOrDefault(
                manitoProfile.profileImageUrl,
                0.15 * width, // 프로필 이미지 크기
              ),
              SizedBox(width: 0.03 * width), // 작은 간격
              Text(manitoProfile.nickname),
            ],
          ),
        ),
        SizedBox(height: 0.03 * width), // 수직 간격
        // 미션 설명 이미지
        detailPost.imageUrlList!.isNotEmpty
            ? ImageSlider(
              images: detailPost.imageUrlList!,
              width: width,
              boxFit: BoxFit.contain,
            )
            : const SizedBox.shrink(),
        // 설명 글
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 0.05 * width, // 좌우 패딩
            vertical: 0.02 * width, // 상하 패딩
          ),
          child: Text(detailPost.description!),
        ),
      ],
    );
  }
}

/// 미션 추측 내용
class _GuessSection extends StatelessWidget {
  const _GuessSection({
    required this.width,
    required this.detailPost,
    required this.creatorProfile,
  });

  final double width;
  final Post detailPost;
  final creatorProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 작성자 프로필 (추측 작성자)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
          child: Row(
            children: [
              profileImageOrDefault(
                creatorProfile?.profileImageUrl, // null 처리
                0.15 * width, // 프로필 이미지 크기
              ),
              SizedBox(width: 0.03 * width), // 작은 간격
              Text(
                creatorProfile?.nickname ?? '알 수 없음',
              ), // creatorProfile이 null일 수 있음
            ],
          ),
        ),
        SizedBox(height: 0.03 * width), // 수직 간격
        // 추측 글
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 0.05 * width, // 좌우 패딩
            vertical: 0.03 * width, // 상하 패딩
          ),
          child: Text(detailPost.guess!),
        ),
      ],
    );
  }
}

/// 댓글창
class _CommentList extends StatelessWidget {
  const _CommentList({
    required this.width,
    required this.comments,
    required this.friendsController,
  });

  final double width;
  final RxList<Comment> comments; // Obx로 감싸진 리스트이므로 RxList로 받음
  final FriendsController friendsController;

  @override
  Widget build(BuildContext context) {
    return comments.isEmpty
        ? Container(
          height: 0.2 * width,
          alignment: Alignment.center,
          child: Text('댓글이 없습니다.'),
        )
        : Align(
          alignment: Alignment.topCenter,
          child: ListView.builder(
            reverse: true, // 최신 댓글이 아래에 오도록
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(), // 부모 SingleChildScrollView와 충돌 방지
            padding: EdgeInsets.zero,
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final Comment comment = comments[index];
              final userProfile = friendsController.searchFriendProfile(
                comment.userId,
              );
              return Container(
                margin: EdgeInsets.only(
                  top: 0.02 * width, // 상단 마진
                  bottom: 0.02 * width, // 하단 마진
                  left: 0.04 * width, // 좌측 마진
                  right: 0.04 * width, // 우측 마진
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    profileImageOrDefault(
                      userProfile?.profileImageUrl, // null 처리
                      0.11 * width, // 댓글 프로필 이미지 크기
                    ),
                    SizedBox(width: 0.03 * width), // 간격
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                userProfile?.nickname ?? '알 수 없음', // null 처리
                                style: Get.textTheme.bodySmall,
                              ),
                              SizedBox(width: 0.02 * width), // 간격
                              Text(
                                timeago.format(comment.createdAt, locale: 'ko'),
                                style: Get.textTheme.labelSmall,
                              ),
                            ],
                          ),
                          SizedBox(height: 0.016 * width), // 작은 간격
                          Text(
                            comment.comment,
                            style: Get.textTheme.bodyMedium,
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
  }
}

/// 채팅 입력창
class _MessageBar extends StatelessWidget {
  final TextEditingController messageTextController;
  final VoidCallback onSendPressed;
  const _MessageBar({
    required this.messageTextController,
    required this.onSendPressed,
  });

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.all(0.02 * width),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageTextController,
              minLines: 1,
              maxLines: 3,
              maxLength: 99,
              // autofocus: true,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: '댓글 입력',
                hintStyle: Get.textTheme.labelLarge,
                counterText: '',
                contentPadding: EdgeInsets.all(0.02 * width),
              ),
            ),
          ),
          SizedBox(width: 0.02 * width),
          ElevatedButton.icon(
            label: Padding(
              padding: EdgeInsets.only(top: 0.01 * width),
              child: Icon(CustomIcons.send, size: 0.05 * width),
            ),
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              padding: EdgeInsets.zero,
              minimumSize: Size(0.1 * width, 0.1 * width),
            ),
            onPressed: onSendPressed,
          ),
        ],
      ),
    );
  }
}
