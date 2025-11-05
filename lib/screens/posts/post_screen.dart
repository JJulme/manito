import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/features/badge/badge_provider.dart';
import 'package:manito/features/posts/post.dart';
import 'package:manito/features/posts/post_provider.dart';
import 'package:manito/features/profiles/profile.dart';
import 'package:manito/features/profiles/profile_provider.dart';
import 'package:manito/main.dart';
import 'package:manito/share/main_appbar.dart';
import 'package:manito/widgets/post_item.dart';
import 'package:manito/widgets/banner_ad_widget.dart';

class PostScreen extends ConsumerStatefulWidget {
  const PostScreen({super.key});

  @override
  ConsumerState<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends ConsumerState<PostScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  // Constants
  static const double _horizontalPadding = 0.03;
  static const double _verticalSpacing = 0.02;
  static const double _borderRadius = 0.02;
  static const double _bannerPadding = 0.06;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(postsProvider.notifier).fetchPosts();
      // 친구 목록 데이터가 없을경우
      final friendListState = ref.read(friendProfilesProvider);
      if (friendListState.isLoading || friendListState.friendList.isEmpty) {
        ref.read(friendProfilesProvider.notifier).fetchFriendList();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  // 본체
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final postState = ref.watch(postsProvider);
    final friendProfilesState = ref.watch(friendProfilesProvider);
    return Scaffold(
      appBar: MainAppbar(text: '기록'),
      body: SafeArea(child: _buildBody(postState, friendProfilesState)),
    );
  }

  // 바디
  Widget _buildBody(
    PostsState postState,
    FriendProfilesState friendProfilesState,
  ) {
    // 로딩
    if (postState.isLoading || friendProfilesState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // 오류
    else if (postState.error != null && postState.postList.isEmpty) {
      return const Center(child: Text('게시물을 불러올 수 없습니다'));
    }
    // 게시물이 없음
    else if (postState.postList.isEmpty) {
      return const Center(child: Text('게시물이 없습니다'));
    }
    //
    else {
      return RefreshIndicator(
        onRefresh: () => ref.read(postsProvider.notifier).fetchPosts(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildBannerAd(),
              SizedBox(height: width * _verticalSpacing),
              _buildPostList(postState),
            ],
          ),
        ),
      );
    }
  }

  // 광고
  Widget _buildBannerAd() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * _horizontalPadding),
      child: BannerAdWidget(
        borderRadius: width * _borderRadius,
        androidAdId: dotenv.env['BANNER_POST_ANDROID']!,
        iosAdId: dotenv.env['BANNER_POST_IOS']!,
      ),
    );
  }

  // 포스트 리스트뷰
  Widget _buildPostList(PostsState postState) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: postState.postList.length,
      itemBuilder:
          (context, index) => _buildPostItem(postState.postList[index]),
    );
  }

  // 포스트 아이템
  Widget _buildPostItem(Post post) {
    final FriendProfile manitoProfile =
        ref
            .read(friendProfilesProvider.notifier)
            .searchFriendProfile(post.manitoId!)!;
    final FriendProfile creatorProfile =
        ref
            .read(friendProfilesProvider.notifier)
            .searchFriendProfile(post.creatorId!)!;
    final int badgeCount = ref.watch(
      specificBadgeByIdProvider((type: 'post_comment', typeId: post.id!)),
    );

    return PostItem(
      post: post,
      manitoProfile: manitoProfile,
      creatorProfile: creatorProfile,
      badgeCount: badgeCount,
    );
  }
}
