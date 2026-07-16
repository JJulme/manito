import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/core/widget/banner_ad_widget.dart';
import 'package:manito/core/widget/common_badge.dart';
import 'package:manito/core/widget/common_error_widget.dart';
import 'package:manito/core/widget/common_loading_widget.dart';
import 'package:manito/core/widget/common_popup_menu_item.dart';
import 'package:manito/core/widget/main_appbar.dart';
import 'package:manito/core/widget/profile_image_view.dart';
import 'package:manito/features_new/friends/domain/entities/friend_entity.dart';
import 'package:manito/features_new/friends/presentation/providers/friend_list_provider.dart';
import 'package:manito/main.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // 친구 상세 화면 이동
  void _toFriendDetail(FriendProfileEntity friendProfile) {
    context.pushNamed(
      'userDetail',
      pathParameters: {'userId': friendProfile.id},
    );
  }

  // 친구 목록 새로고침
  Future<void> _handleRefresh() async {
    await ref.read(friendListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final friendsAsync = ref.watch(friendListProvider);
    return Scaffold(
      appBar: MainAppbar(
        title: Text('친구', style: Theme.of(context).textTheme.headlineSmall),
        actions: [_buildPopupMenu()],
      ),
      body: SafeArea(
        child: friendsAsync.when(
          loading: () => const CommonLoadingWidget(),
          error:
              (error, stackTrace) => CommonErrorWidget(
                error: error,
                onRetry: () => ref.invalidate(friendListProvider),
              ),
          data: (data) {
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              child: _buildFriendsList(data),
            );
          },
        ),
      ),
    );
  }

  // 앱바 팝업 버튼
  Widget _buildPopupMenu() {
    // int badgeCount = ref.watch(specificBadgeProvider('friend_request'));
    return PopupMenuButton(
      icon: CommonBadge(badgeCount: 0, child: Icon(Icons.more_vert)),
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == '/friend_requests') {
          // ref.read(badgeProvider.notifier).resetBadgeCount('friend_request');
          context.push(value);
        } else {
          context.push(value);
        }
      },
      itemBuilder:
          (context) => [
            CommonPopupMenuItem(
              icon: Icon(Icons.person_add_alt_1_rounded),
              text: '친구 찾기',
              value: '/user_search',
            ),
            CommonPopupMenuItem(
              icon: CommonBadge(
                badgeCount: 0,
                child: Icon(Icons.supervisor_account_rounded),
              ),
              text: '친구 요청',
              value: '/friend_requests',
            ),
            CommonPopupMenuItem(
              icon: Icon(Icons.no_accounts_rounded),
              text: '차단 목록',
              value: '/blocked_users',
            ),
          ],
    );
  }

  // 친구 목록
  Widget _buildFriendsList(List<FriendProfileEntity> friendList) {
    if (friendList.isEmpty) {
      return SizedBox(height: width, child: Center(child: Text('친구를 추가해보세요!')));
    } else {
      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              shrinkWrap: false,
              itemCount: friendList.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    children: [
                      _buildBannerAd(),
                      SizedBox(height: width * 0.03),
                      _buildFriendItem(friendList[index]),
                    ],
                  );
                }
                return _buildFriendItem(friendList[index]);
              },
            ),
          ),
        ],
      );
    }
  }

  // 광고
  Widget _buildBannerAd() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.03),
      child: BannerAdWidget(
        borderRadius: width * 0.02,
        androidAdId: dotenv.env['BANNER_FRIENDS_ANDROID']!,
        iosAdId: dotenv.env['BANNER_FRIENDS_IOS']!,
      ),
    );
  }

  // 친구 항목
  Widget _buildFriendItem(FriendProfileEntity friendProfile) {
    return InkWell(
      onTap: () => _toFriendDetail(friendProfile),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.03,
          vertical: width * 0.02,
        ),
        child: Row(
          children: [
            ProfileImageView(
              size: width * 0.15,
              profileImageUrl: friendProfile.profileImageUrl,
            ),
            SizedBox(width: width * 0.035),
            Expanded(child: _buildFriendInfo(friendProfile)),
            _buildMissionBadge(friendProfile.progressMissions),
          ],
        ),
      ),
    );
  }

  // 친구 이름, 상태메시지
  Widget _buildFriendInfo(FriendProfileEntity friendProfile) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          friendProfile.displayName,
          style: Theme.of(context).textTheme.bodyLarge,
          overflow: TextOverflow.ellipsis,
        ),
        friendProfile.statusMessage == ''
            ? SizedBox.shrink()
            : Text(
              friendProfile.statusMessage!,
              style: Theme.of(context).textTheme.labelMedium,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
      ],
    );
  }

  // 진행중인 미션 개수 아이콘
  Widget _buildMissionBadge(int count) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        SvgPicture.asset(
          'assets/icons/star.svg',
          width: width * 0.08,
          colorFilter: ColorFilter.mode(
            count == 0
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.tertiary,
            BlendMode.srcIn,
          ),
        ),
        Positioned(
          child: Text(
            count.toString(),
            textAlign: TextAlign.center,
            // style: TextStyle(color: Colors.white, fontSize: width * 0.045),
          ),
        ),
      ],
    );
  }
}
