import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/features_new/posts/domain/entities/post_entity.dart';
import 'package:manito/features_new/posts/presentation/providers/posts_provider.dart';
import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';
import 'package:manito/features_new/profile/presentation/providers/my_profile_provider.dart';
import 'package:manito/main.dart';
import 'package:manito/share/constants.dart';
import 'package:manito/share/report_bottomsheet.dart';
import 'package:manito/share/sub_appbar.dart';
import 'package:manito/widgets/image_slider.dart';
import 'package:manito/core/custom_icons.dart';
import 'package:manito/core/widget/profile_image_view.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final commentController = TextEditingController();

  // 댓글 달기
  void _handleMessageBar() {
    if (commentController.text.trim().isNotEmpty) {
      ref
          .read(postCommentProvider(widget.postId).notifier)
          .insertComment(widget.postId, commentController.text);
      commentController.clear();
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentAsync = ref.watch(postCommentProvider(widget.postId));
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: postAsync.when(
        loading:
            () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error:
            (error, stackTrace) =>
                Scaffold(body: Center(child: Text('Error: $error'))),
        data: (postDetail) {
          if (postDetail == null) {
            return const Scaffold(body: Center(child: Text('게시글을 찾을 수 없습니다.')));
          }
          return Scaffold(
            appBar: _buildAppBar(postDetail),
            body: SafeArea(child: _buildBody(postDetail, commentAsync)),
          );
        },
      ),
    );
  }

  void _handleReportPost() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return ReportBottomsheet(reportIdType: 'post', postId: widget.postId);
      },
    );
  }

  PreferredSizeWidget _buildAppBar(PostEntity postDetail) {
    return SubAppbar(
      title: Row(
        children: [
          Icon(iconMap[postDetail.contentType]),
          SizedBox(width: width * 0.02),
          Expanded(
            child: AutoSizeText(
              postDetail.content ?? '',
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
        icon: const Icon(Icons.more_vert),
        position: PopupMenuPosition.under,
        itemBuilder:
            (context) => [
              PopupMenuItem(
                onTap: _handleReportPost,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.report_problem_rounded),
                    SizedBox(width: width * 0.02),
                    const Text('신고하기'),
                  ],
                ),
              ),
            ],
      ),
    );
  }

  // 전체, 댓글창
  Widget _buildBody(
    PostEntity postDetail,
    AsyncValue<List<CommentEntity>> commentAsync,
  ) {
    return Column(
      children: [
        Expanded(child: _buildContent(postDetail, commentAsync)),
        _buildMessageBar(),
      ],
    );
  }

  // 마니또 활동, 생성자 추측, 댓글 목록
  Widget _buildContent(
    PostEntity postDetail,
    AsyncValue<List<CommentEntity>> commentAsync,
  ) {
    final manitoProfileAsync = ref.watch(
      userProfileProvider(postDetail.manitoId ?? ''),
    );
    final creatorProfileAsync = ref.watch(
      userProfileProvider(postDetail.creatorId ?? ''),
    );
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfile(manitoProfileAsync),
          SizedBox(height: width * 0.03),
          _buildImageSection(postDetail),
          _buildTextSection(postDetail.description ?? ''),
          const Divider(),
          _buildProfile(creatorProfileAsync),
          SizedBox(height: width * 0.03),
          _buildTextSection(postDetail.guess ?? ''),
          const Divider(),
          _buildCommentSection(commentAsync),
          SizedBox(height: width * 0.05),
        ],
      ),
    );
  }

  // 생성자, 마니또 프로필
  Widget _buildProfile(AsyncValue<UserEntity> profileAsync) {
    return profileAsync.when(
      loading: () => SizedBox(height: width * 0.15),
      error: (error, stackTrace) => SizedBox(height: width * 0.15),
      data: (profile) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05),
          child: Row(
            children: [
              ProfileImageView(
                size: width * 0.15,
                profileImageUrl: profile.profileImageUrl ?? '',
              ),
              SizedBox(width: width * 0.03),
              Text(profile.nickname, style: TextTheme.of(context).bodyLarge),
            ],
          ),
        );
      },
    );
  }

  // 이미지 슬라이더
  Widget _buildImageSection(PostEntity postDetail) {
    if (postDetail.imageUrlList?.isEmpty ?? true) {
      return const SizedBox.shrink();
    }
    return ImageSlider(
      images: postDetail.imageUrlList!.cast<String>(),
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
  Widget _buildCommentSection(AsyncValue<List<CommentEntity>> commentAsync) {
    return commentAsync.when(
      loading:
          () => Container(
            height: width * 0.2,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
      error:
          (error, stackTrace) => Container(
            height: width * 0.2,
            alignment: Alignment.center,
            child: Text('Error: $error'),
          ),
      data: (comments) {
        if (comments.isEmpty) {
          return Center(
            child: Text(
              '댓글을 작성해 주세요',
              style: Theme.of(context).textTheme.bodyMedium,
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
            itemCount: comments.length,
            itemBuilder:
                (context, index) => _buildCommentItem(
                  comments[index].userId,
                  comments[index],
                ),
          ),
        );
      },
    );
  }

  // 댓글 아이템
  Widget _buildCommentItem(String userId, CommentEntity comment) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    return profileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (profile) {
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: width * 0.04,
            vertical: 0.03,
          ),
          padding: EdgeInsets.symmetric(vertical: width * 0.015),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 이미지
              ProfileImageView(
                size: width * 0.11,
                profileImageUrl: profile.profileImageUrl!,
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
                          style: TextTheme.of(context).bodyLarge,
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
      },
    );
  }

  // 댓글창
  Widget _buildMessageBar() {
    return Padding(
      padding: EdgeInsets.all(width * 0.02),
      child: Row(
        children: [
          // 입력창
          Expanded(
            child: TextField(
              minLines: 1,
              maxLines: 3,
              maxLength: 99,
              controller: commentController,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: '댓글 입력',
                hintStyle: Theme.of(context).textTheme.labelLarge,
                filled: true,
                fillColor: ColorScheme.of(context).primaryContainer,
                counterText: '',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: width * 0.045,
                  vertical: width * 0.03,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(width * 0.07),
                ),
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
            onPressed: () => _handleMessageBar(),
          ),
        ],
      ),
    );
  }
}
