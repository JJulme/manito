import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/features/badge/badge_provider.dart';
import 'package:manito/features/friends/friends_provider.dart';
import 'package:manito/features/posts/post.dart';
import 'package:manito/features/posts/post_provider.dart';
import 'package:manito/features/profiles/profile.dart';
import 'package:manito/features/profiles/profile_provider.dart';
import 'package:manito/main.dart';
import 'package:manito/share/common_dialog.dart';
import 'package:manito/share/custom_popup_menu_item.dart';
import 'package:manito/share/report_bottomsheet.dart';
import 'package:manito/share/sub_appbar.dart';
import 'package:manito/widgets/post_item.dart';
import 'package:manito/widgets/profile_item.dart';
import 'package:manito/widgets/banner_ad_widget.dart';

class FriendsDetailScreen extends ConsumerStatefulWidget {
  final String friendId;
  const FriendsDetailScreen({super.key, required this.friendId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FriendsDetailScreenState();
}

class _FriendsDetailScreenState extends ConsumerState<FriendsDetailScreen> {
  static const double _horizontalPadding = 0.03;
  static const double _borderRadius = 0.02;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 포스트를 가져온적 없는 경우
      final postsState = ref.read(postsProvider);
      if (postsState.isLoading || postsState.postList.isEmpty) {
        ref.read(postsProvider.notifier).fetchPosts();
      }
    });
  }

  void _toFriendEdit(FriendProfile friendProfile) {
    context.push('/friends_edit', extra: friendProfile);
  }

  Future<void> _handleBlackFriend() async {
    final result = await DialogHelper.showConfirmDialog(
      context,
      message: context.tr("friends_detail_screen.dialog_message"),
    );
    if (result == true) {
      final friendId = widget.friendId;
      await ref.read(blacklistServiceProvider).blockFriend(friendId);
      ref.read(friendProfilesProvider.notifier).refreash();
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  void _handleReportUser() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return ReportBottomsheet(
          userId: ref.read(userProfileProvider).userProfile!.id,
          reportIdType: 'user',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendProfile = ref.watch(friendDetailProvider(widget.friendId));
    final postsState = ref.watch(postsProvider);
    if (friendProfile == null) {
      return Scaffold(
        appBar: SubAppbar(title: Text('')),
        body: Center(child: Text('친구정보를 찾을 수 없습니다.')),
      );
    }
    return Scaffold(
      appBar: SubAppbar(
        title: SizedBox.shrink(),
        actions: [_buildPopupMenu(friendProfile)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ProfileItem(
                profileImageUrl: friendProfile.profileImageUrl!,
                name: friendProfile.displayName,
                statusMessage: friendProfile.statusMessage!,
              ),
              SizedBox(height: width * 0.03),
              _buildBannerAd(),
              SizedBox(height: width * 0.03),
              _buildPostList(postsState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(FriendProfile friendProfile) {
    return Padding(
      padding: EdgeInsets.only(right: width * 0.02),
      child: PopupMenuButton(
        icon: Icon(Icons.more_vert),
        itemBuilder:
            (context) => [
              CustomPopupMenuItem(
                icon: Icon(Icons.edit),
                text: '이름 수정',
                value: '',
                onTap: () => _toFriendEdit(friendProfile),
              ),
              CustomPopupMenuItem(
                icon: Icon(Icons.no_accounts_rounded),
                text: '친구 차단',
                value: '',
                onTap: () => _handleBlackFriend(),
              ),
              CustomPopupMenuItem(
                icon: Icon(Icons.report_problem_rounded),
                text: '신고하기',
                value: '',
                onTap: _handleReportUser,
              ),
            ],
      ),
    );
  }

  // 광고
  Widget _buildBannerAd() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * _horizontalPadding),
      child: BannerAdWidget(
        borderRadius: width * _borderRadius,
        androidAdId: dotenv.env['BANNER_FRIEND_DETAIL_ANDROID']!,
        iosAdId: dotenv.env['BANNER_FRIEND_DETAIL_IOS']!,
      ),
    );
  }

  // 포스트 리스트뷰
  Widget _buildPostList(PostsState postsState) {
    final postList = ref
        .read(postsProvider.notifier)
        .getPostsWithFriend(widget.friendId);
    if (postsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (postsState.error != null && postsState.postList.isEmpty) {
      return const Center(child: Text('게시물을 불러올 수 없습니다'));
    } else if (postList.isEmpty) {
      return const Center(child: Text('게시물이 없습니다'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: postList.length,
      itemBuilder: (context, index) => _buildPostItem(postList[index]),
    );
  }

  // 포스트 아이템
  Widget _buildPostItem(Post post) {
    final FriendProfile manitoProfile = ref
        .read(friendProfilesProvider.notifier)
        .searchFriendProfile(post.manitoId!);
    final FriendProfile creatorProfile = ref
        .read(friendProfilesProvider.notifier)
        .searchFriendProfile(post.creatorId!);
    final int badgeCount = ref.watch(specificBadgeProvider(post.id!));

    return PostItem(
      post: post,
      manitoProfile: manitoProfile,
      creatorProfile: creatorProfile,
      badgeCount: badgeCount,
    );
  }
}
