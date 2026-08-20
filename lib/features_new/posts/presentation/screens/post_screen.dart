import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/badge/presentation/providers/badge_provider.dart';
import 'package:manito/features_new/posts/domain/entities/post_entity.dart';
import 'package:manito/features_new/posts/presentation/providers/posts_provider.dart';
import 'package:manito/main.dart';
import 'package:manito/share/main_appbar.dart';
import 'package:manito/features_new/posts/presentation/widgets/post_item.dart';
import 'package:manito/core/widget/banner_ad_widget.dart';

class PostScreen extends ConsumerStatefulWidget {
  const PostScreen({super.key});

  @override
  ConsumerState<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends ConsumerState<PostScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  // Constants
  static const double _horizontalPadding = 0.03;
  static const double _borderRadius = 0.02;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final postAsync = ref.watch(postsProvider);
    return Scaffold(
      appBar: MainAppbar(
        title: Text('기록', style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: SafeArea(child: _buildBody(postAsync)),
    );
  }

  // 바디
  Widget _buildBody(
    AsyncValue<List<PostEntity>> postAsync,
  ) {
    return postAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => const Center(child: Text('게시물을 불러올 수 없습니다')),
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(child: Text('게시물이 없습니다'));
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(postsProvider.notifier).refresh(),
          child: _buildPostList(posts),
        );
      },
    );
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
  Widget _buildPostList(List<PostEntity> posts) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            shrinkWrap: false,
            itemCount: posts.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    _buildBannerAd(),
                    SizedBox(height: width * 0.02),
                    _buildPostItem(posts[index]),
                  ],
                );
              }
              return _buildPostItem(posts[index]);
            },
          ),
        ),
      ],
    );
  }

  // 포스트 아이템
  Widget _buildPostItem(PostEntity post) {
    final int badgeCount = ref.watch(
      specificBadgeByIdProvider((type: 'post_comment', typeId: post.id!)),
    );

    return PostItem(
      post: post,
      manitoId: post.manitoId!,
      creatorId: post.creatorId!,
      badgeCount: badgeCount,
    );
  }
}
