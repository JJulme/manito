import 'package:easy_localization/easy_localization.dart';
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

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late final PostDetailController _controller;
  late final FriendsController _friendsController;

  // Constants
  static const double _bottomSpacing = 0.05;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(PostDetailController());
    _friendsController = Get.find<FriendsController>();
  }

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
        appBar: _buildAppBar(),
        body: SafeArea(child: _buildBody(width)),
      ),
    );
  }

  // 앱바
  AppBar _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Get.back(),
      ),
      title: Obx(() {
        if (_controller.isLoading.value) {
          return const SizedBox.shrink();
        }
        return Text(
          '${_controller.post.deadlineType} / ${_controller.post.content}',
          style: Get.textTheme.headlineSmall,
        );
      }),
    );
  }

  // 바디
  Widget _buildBody(double screenWidth) {
    return Column(
      children: [
        Expanded(child: _buildContent(screenWidth)),
        _buildMessageBar(screenWidth),
      ],
    );
  }

  // 바디 컬럼
  Widget _buildContent(double screenWidth) {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final detailPost = _controller.detailPost.value!;
      return SingleChildScrollView(
        controller: _controller.commentScrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostHeader(screenWidth, detailPost),
            const Divider(),
            _buildGuessSection(screenWidth, detailPost),
            const Divider(),
            _buildCommentSection(screenWidth),
            SizedBox(height: _bottomSpacing * screenWidth),
          ],
        ),
      );
    });
  }

  // 미션 게시물
  Widget _buildPostHeader(double screenWidth, Post detailPost) {
    return _PostHeader(
      width: screenWidth,
      detailPost: detailPost,
      manitoProfile: _controller.manitoProfile,
    );
  }

  // 미션 추측물
  Widget _buildGuessSection(double screenWidth, Post detailPost) {
    return _GuessSection(
      width: screenWidth,
      detailPost: detailPost,
      creatorProfile: _controller.creatorProfile,
    );
  }

  // 댓글 목록
  Widget _buildCommentSection(double screenWidth) {
    return Obx(() {
      if (_controller.commentLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return _CommentList(
        width: screenWidth,
        comments: _controller.commentList,
        friendsController: _friendsController,
      );
    });
  }

  // 댓글 입력창
  Widget _buildMessageBar(double screenWidth) {
    return _MessageBar(
      width: screenWidth,
      messageTextController: _controller.commentController,
      onSendPressed: _handleSendComment,
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
  final dynamic manitoProfile;

  static const double _horizontalPadding = 0.05;
  static const double _verticalSpacing = 0.03;
  static const double _smallSpacing = 0.02;
  static const double _profileImageSize = 0.15;

  // 본체
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileSection(),
        SizedBox(height: width * _verticalSpacing),
        _buildImageSection(),
        _buildDescriptionSection(),
      ],
    );
  }

  // 마니또 프로필 화면
  Widget _buildProfileSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _horizontalPadding * width),
      child: Row(
        children: [
          profileImageOrDefault(
            manitoProfile.profileImageUrl,
            _profileImageSize * width,
          ),
          SizedBox(width: _verticalSpacing * width),
          Text(manitoProfile.nickname),
        ],
      ),
    );
  }

  // 이미지 리스트
  Widget _buildImageSection() {
    if (detailPost.imageUrlList?.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    return ImageSlider(
      images: detailPost.imageUrlList!,
      width: width,
      boxFit: BoxFit.contain,
    );
  }

  // 미션 설명
  Widget _buildDescriptionSection() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _horizontalPadding * width,
        vertical: _smallSpacing * width,
      ),
      child: Text(detailPost.description ?? ''),
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
  final dynamic creatorProfile;

  static const double _horizontalPadding = 0.05;
  static const double _verticalSpacing = 0.03;
  static const double _profileImageSize = 0.15;

  // 본체
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCreatorProfile(),
        SizedBox(height: 0.03 * width),
        _buildGuessContent(),
      ],
    );
  }

  // 생성자 프로필
  Widget _buildCreatorProfile() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _horizontalPadding * width),
      child: Row(
        children: [
          profileImageOrDefault(
            creatorProfile?.profileImageUrl,
            _profileImageSize * width,
          ),
          SizedBox(width: _verticalSpacing * width),
          Text(creatorProfile?.nickname ?? '알 수 없음'),
        ],
      ),
    );
  }

  // 생성자의 추측 내용
  Widget _buildGuessContent() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _horizontalPadding * width,
        vertical: _verticalSpacing * width,
      ),
      child: Text(detailPost.guess ?? ''),
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

  static const double _emptyStateHeight = 0.2;
  static const double _commentSpacing = 0.04;
  static const double _smallSpacing = 0.02;
  static const double _verticalSpacing = 0.03;
  static const double _commentPadding = 0.016;
  static const double _commentProfileSize = 0.11;

  // 본체
  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return Container(
        height: width * _emptyStateHeight,
        alignment: Alignment.center,
        child:
            Text(
              "post_detail_screen.no_comment",
              style: Get.textTheme.bodyMedium,
            ).tr(),
      );
    }
    return _buildCommentListView();
  }

  // 댓글 목록 리스트
  Widget _buildCommentListView() {
    return Align(
      alignment: Alignment.topCenter,
      child: ListView.builder(
        reverse: true,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: comments.length,
        itemBuilder: (context, index) => _buildCommentItem(comments[index]),
      ),
    );
  }

  // 프로필 이미지
  Widget _buildCommentItem(Comment comment) {
    final userProfile = friendsController.searchFriendProfile(comment.userId);
    return Container(
      margin: EdgeInsets.all(
        _smallSpacing * width,
      ).copyWith(left: _commentSpacing * width, right: _commentSpacing * width),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          profileImageOrDefault(
            userProfile?.profileImageUrl,
            _commentProfileSize * width,
          ),
          SizedBox(width: _verticalSpacing * width),
          Expanded(child: _buildCommentContent(comment, userProfile)),
        ],
      ),
    );
  }

  // 프로필 이름, 생성일, 댓글
  Widget _buildCommentContent(Comment comment, dynamic userProfile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentHeader(comment, userProfile),
        SizedBox(height: _commentPadding * width),
        _buildCommentText(comment),
      ],
    );
  }

  // 프로필 이름, 생성일
  Widget _buildCommentHeader(Comment comment, dynamic userProfile) {
    return Row(
      children: [
        Text(userProfile?.nickname ?? '알 수 없음', style: Get.textTheme.bodySmall),
        SizedBox(width: _smallSpacing * width),
        Text(
          timeago.format(comment.createdAt, locale: 'ko'),
          style: Get.textTheme.labelSmall,
        ),
      ],
    );
  }

  // 댓글
  Widget _buildCommentText(Comment comment) {
    return Text(
      comment.comment,
      style: Get.textTheme.bodyMedium,
      softWrap: true,
    );
  }
}

/// 채팅 입력창
class _MessageBar extends StatelessWidget {
  const _MessageBar({
    required this.width,
    required this.messageTextController,
    required this.onSendPressed,
  });
  final double width;
  final TextEditingController messageTextController;
  final VoidCallback onSendPressed;
  static const double _messageBarPadding = 0.02;
  static const double _sendButtonSize = 0.1;
  static const double _sendIconPadding = 0.01;
  static const double _sendIconSize = 0.05;
  static const int _maxCommentLength = 99;
  static const int _maxTextLines = 3;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.all(0.02 * width),
      child: Row(
        children: [
          Expanded(child: _buildTextField(context)),
          SizedBox(width: 0.02 * width),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context) {
    return TextField(
      controller: messageTextController,
      minLines: 1,
      maxLines: _maxTextLines,
      maxLength: _maxCommentLength,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        hintText: context.tr("post_detail_screen.write_comment"),
        hintStyle: Get.textTheme.labelLarge,
        counterText: '',
        contentPadding: EdgeInsets.all(_messageBarPadding * width),
      ),
    );
  }

  Widget _buildSendButton() {
    return ElevatedButton.icon(
      label: Padding(
        padding: EdgeInsets.only(top: _sendIconPadding * width),
        child: Icon(CustomIcons.send, size: _sendIconSize * width),
      ),
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: EdgeInsets.zero,
        minimumSize: Size(_sendButtonSize * width, _sendButtonSize * width),
      ),
      onPressed: onSendPressed,
    );
  }
}
