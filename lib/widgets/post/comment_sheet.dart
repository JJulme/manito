import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/badge_controller.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/controllers/post_controller.dart';
import 'package:manito/custom_icons.dart';
import 'package:manito/models/comment.dart';
import 'package:manito/models/user_profile.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class CommentSheet extends StatefulWidget {
  final double width;

  final String missionId;
  const CommentSheet({super.key, required this.width, required this.missionId});

  @override
  State<CommentSheet> createState() => _CommentSheet2State();
}

class _CommentSheet2State extends State<CommentSheet> {
  late final CommentController _controller;
  final FriendsController _friendsController = Get.find<FriendsController>();
  // final BadgeController _badgeController = Get.find<BadgeController>();

  @override
  void initState() {
    super.initState();
    // 컨트롤러 초기화
    _controller = Get.put(CommentController(widget.missionId));
  }

  // @override
  // void dispose() {
  //   _badgeController.clearComment(widget.missionId);
  //   super.dispose();
  // }

  /// 댓글 공백 입력 방지
  void _handleSendComment() {
    if (_controller.commentController.text.trim().isNotEmpty) {
      _controller.insertComment();
      _controller.commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.focusScope?.unfocus(),
      child: Container(
        height: Get.height * 0.96,
        width: Get.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(0.06 * widget.width),
          ),
        ),
        child: Column(
          children: [
            // 바텀 시트 핸들
            Container(
              height: 0.02 * widget.width,
              width: 0.2 * widget.width,
              margin: EdgeInsets.only(
                top: 0.03 * widget.width,
                bottom: 0.02 * widget.width,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 댓글 목록
            Expanded(
              child: Obx(() {
                if (_controller.isLoading.value) {
                  return Center(child: CircularProgressIndicator());
                } else if (_controller.commentList.isEmpty) {
                  return Center(child: Text('댓글이 없습니다'));
                } else {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ListView.builder(
                      reverse: true,
                      shrinkWrap: true,
                      padding: EdgeInsets.all(0),
                      itemCount: _controller.commentList.length,
                      itemBuilder: (context, index) {
                        final Comment comment = _controller.commentList[index];
                        final UserProfile? userProfile = _friendsController
                            .searchFriendProfile(comment.userId);
                        return Container(
                          margin: EdgeInsets.only(
                            top: 0.02 * widget.width,
                            bottom: 0.02 * widget.width,
                            left: 0.04 * widget.width,
                            right: 0.04 * widget.width,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              profileImageOrDefault(
                                userProfile!.profileImageUrl,
                                0.13 * widget.width,
                              ),
                              SizedBox(width: 0.03 * widget.width),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          userProfile.nickname,
                                          style: Get.textTheme.bodySmall,
                                        ),
                                        SizedBox(width: 0.02 * widget.width),
                                        Text(
                                          comment.createdAt,
                                          style: Get.textTheme.labelSmall,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 0.016 * widget.width),
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
              }),
            ),
            // 채팅창
            Padding(
              padding: EdgeInsets.only(
                top: 0.02 * widget.width,
                bottom: 0.02 * widget.width,
                right: 0.02 * widget.width,
                left: 0.02 * widget.width,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller.commentController,
                      minLines: 1,
                      maxLines: 3,
                      maxLength: 99,
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            required isFocused,
                            required maxLength,
                          }) => null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: '메시지 입력',
                        hintStyle: Get.textTheme.labelLarge,
                        contentPadding: EdgeInsets.all(0.02 * widget.width),
                      ),
                    ),
                  ),
                  SizedBox(width: 0.02 * widget.width),
                  ElevatedButton.icon(
                    label: Icon(CustomIcons.send),
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.zero,
                      minimumSize: Size(0.1 * widget.width, 0.1 * widget.width),
                    ),
                    onPressed: _handleSendComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
