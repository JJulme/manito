import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/features/posts/post.dart';
import 'package:manito/features/posts/post_provider.dart';
import 'package:manito/features/profiles/profile.dart';
import 'package:manito/features/profiles/profile_provider.dart';
import 'package:manito/main.dart';
import 'package:manito/share/constants.dart';
import 'package:manito/share/report_bottomsheet.dart';
import 'package:manito/share/sub_appbar.dart';
import 'package:manito/widgets/image_slider.dart';
import 'package:manito/core/custom_icons.dart';
import 'package:manito/widgets/profile_image_view.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostDetailScreen extends ConsumerStatefulWidget {
  final Post post;
  final FriendProfile manitoProfile;
  final FriendProfile creatorProfile;
  const PostDetailScreen({
    super.key,
    required this.post,
    required this.manitoProfile,
    required this.creatorProfile,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  late final StateNotifierProvider<PostDetailNotifier, PostDetailState>
  _postDetailProvider;
  final commentController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _postDetailProvider = createPostDetailProvider(widget.post);
  }

  // late final provider = createPostDetailProvider(widget.post);
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_postDetailProvider);
    final notifier = ref.read(_postDetailProvider.notifier);
    ref.listen<PostDetailState>(_postDetailProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.error!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '다시 시도',
              onPressed: () => notifier.init(),
            ),
          ),
        );
      }
    });
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: SafeArea(child: _buildBody(state, notifier)),
      ),
    );
  }

  void _handleReportPost() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return ReportBottomsheet(
          userId: ref.read(userProfileProvider).userProfile!.id,
          reportIdType: 'post',
          postId: widget.post.id,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return SubAppbar(
      title: Row(
        children: [
          Icon(iconMap[widget.post.contentType], color: Colors.grey[800]),
          SizedBox(width: width * 0.02),
          Expanded(
            child: AutoSizeText(
              widget.post.content!,
              minFontSize: 7,
              maxLines: 1,
            ),
          ),
        ],
      ),
      actions: [_buildPopupMenu()],
    );
  }

  // 앱바 팝업 버튼
  Widget _buildPopupMenu() {
    return Padding(
      padding: EdgeInsets.only(right: width * 0.02),
      child: PopupMenuButton(
        icon: Icon(Icons.more_vert),
        position: PopupMenuPosition.under,
        itemBuilder:
            (context) => [
              PopupMenuItem(
                onTap: _handleReportPost,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.report_problem_rounded),
                    SizedBox(width: width * 0.02),
                    Text('신고하기'),
                  ],
                ),
              ),
            ],
      ),
    );
  }

  // 전체, 댓글창
  Widget _buildBody(PostDetailState state, PostDetailNotifier notifier) {
    return Column(
      children: [
        Expanded(child: _buildContent(state)),
        _buildMessageBar(notifier),
      ],
    );
  }

  // 마니또 활동, 생성자 추측, 댓글 목록
  Widget _buildContent(PostDetailState state) {
    if (state.isLoading || state.postDetail == null) {
      return Center(child: CircularProgressIndicator());
    } else if (state.error != null && state.postDetail == null) {
      return Center(
        child: Text('오류 발생', style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfile(widget.manitoProfile),
          SizedBox(height: width * 0.03),
          _buildImageSection(state),
          _buildTextSection(state.postDetail!.description!),
          Divider(),
          _buildProfile(widget.creatorProfile),
          SizedBox(height: width * 0.03),
          _buildTextSection(state.postDetail!.guess!),
          Divider(),
          _buildCommentSection(state),
          SizedBox(height: width * 0.05),
        ],
      ),
    );
  }

  // 생성자, 마니또 프로필
  Widget _buildProfile(FriendProfile profile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
      child: Row(
        children: [
          ProfileImageView(
            size: width * 0.15,
            profileImageUrl: profile.profileImageUrl!,
          ),
          SizedBox(width: width * 0.03),
          Text(profile.nickname, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  // 이미지 슬라이더
  Widget _buildImageSection(PostDetailState state) {
    if (state.postDetail!.imageUrlList?.isEmpty ?? true) {
      return const SizedBox.shrink();
    }
    return ImageSlider(
      images: state.postDetail!.imageUrlList!,
      boxFit: BoxFit.contain,
    );
  }

  // 마니또 설명과 생성자 추측
  Widget _buildTextSection(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.05,
        vertical: width * 0.02,
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  // 댓글 리스트
  Widget _buildCommentSection(PostDetailState state) {
    if (state.commentList.isEmpty) {
      return Center(
        child: Text(
          '댓글을 작성해 주세요',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ListView.builder(
        reverse: true,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: state.commentList.length,
        itemBuilder:
            (context, index) => _buildCommentItem(
              state.commentList[index].userId,
              state.commentList[index],
            ),
      ),
    );
  }

  // 댓글 아이템
  Widget _buildCommentItem(String userId, Comment comment) {
    final FriendProfile? profile = ref
        .read(friendProfilesProvider.notifier)
        .searchFriendProfile(userId);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: 0.03),
      padding: EdgeInsets.symmetric(vertical: width * 0.015),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 이미지
          ProfileImageView(
            size: width * 0.11,
            profileImageUrl: profile!.profileImageUrl!,
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 이름
                    Text(
                      profile.nickname,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SizedBox(width: width * 0.02),
                    // 작성일
                    Text(
                      timeago.format(comment.createdAt, locale: 'en_short'),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                SizedBox(height: width * 0.015),
                // 댓글 내용
                Text(
                  comment.comment,
                  softWrap: true,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 댓글창
  Widget _buildMessageBar(PostDetailNotifier notifier) {
    return Padding(
      padding: EdgeInsets.all(width * 0.02),
      child: Row(
        children: [
          // 입력창
          Expanded(
            child: TextField(
              controller: commentController,
              minLines: 1,
              maxLines: 3,
              maxLength: 99,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: '댓글 입력',
                hintStyle: Theme.of(context).textTheme.labelLarge,
                counterText: '',
                contentPadding: EdgeInsets.all(width * 0.025),
              ),
            ),
          ),
          SizedBox(width: width * 0.02),
          // 버튼
          ElevatedButton.icon(
            label: Padding(
              padding: EdgeInsets.only(top: width * 0.01),
              child: Icon(CustomIcons.send, size: width * 0.05),
            ),
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            onPressed: () {
              if (commentController.text.trim().isNotEmpty) {
                notifier.insertComment(commentController.text);
                commentController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
