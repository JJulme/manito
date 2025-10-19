import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/features/badge/badge_provider.dart';
import 'package:manito/features/profiles/profile.dart';
import 'package:manito/features/profiles/profile_provider.dart';
import 'package:manito/share/custom_badge.dart';
import 'package:manito/share/custom_popup_menu_item.dart';
import 'package:manito/share/main_appbar.dart';
import 'package:manito/core/constants.dart';
import 'package:manito/widgets/banner_ad_widget.dart';
import 'package:manito/widgets/profile_image_view.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 친구목록 데이터가 없을 경우
      final friendListState = ref.read(friendProfilesProvider);
      if (friendListState.isLoading || friendListState.friendList.isEmpty) {
        ref.read(friendProfilesProvider.notifier).fetchFriendList();
      }
    });
  }

  // 친구 상세 화면 이동
  void _toFriendsDetail(dynamic friendProfile) {
    context.push('/friends_detail', extra: friendProfile);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final double width = MediaQuery.of(context).size.width;
    final friendProfilesState = ref.watch(friendProfilesProvider);

    // 에러 감지
    ref.listen<FriendProfilesState>(friendProfilesProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류')));
      }
    });
    return Scaffold(
      appBar: MainAppbar(
        width: width,
        text: '친구',
        actions: [_buildPopupMenu(width)],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh:
              () =>
                  ref.read(friendProfilesProvider.notifier).refreshFriendList(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildBannerAd(width),
                SizedBox(height: width * 0.03),
                _buildFriendsList(width, friendProfilesState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 앱바 팝업 버튼
  Widget _buildPopupMenu(double width) {
    int badgeCount = ref.watch(specificBadgeProvider('friend_request'));
    return Padding(
      padding: EdgeInsets.only(right: width * 0.02),
      child: PopupMenuButton(
        icon: customBadgeIconWithLabel(
          badgeCount,
          child: Icon(Icons.person_add_alt_1_rounded, size: width * 0.06),
        ),
        position: PopupMenuPosition.under,
        onSelected: (value) {
          if (value == '/friends_request') {
            ref.read(badgeProvider.notifier).resetBadgeCount('friend_request');
            context.push(value);
          } else {
            context.push(value);
          }
        },
        itemBuilder:
            (context) => [
              CustomPopupMenuItem(
                width: width,
                icon: Icon(Icons.person_add_alt_1_rounded),
                text: '친구 찾기',
                value: '/friends_search',
              ),
              CustomPopupMenuItem(
                width: width,
                icon: customBadgeIconWithLabel(
                  badgeCount,
                  child: Icon(Icons.supervisor_account_rounded),
                ),
                text: '친구 요청',
                value: '/friends_request',
              ),
              CustomPopupMenuItem(
                width: width,
                icon: Icon(Icons.no_accounts_rounded),
                text: '차단 목록',
                value: '/friends_blacklist',
              ),
            ],
      ),
    );
  }

  // 광고
  Widget _buildBannerAd(double width) {
    return BannerAdWidget(
      width: width - (width * 0.06),
      borderRadius: width * 0.02,
      androidAdId: dotenv.env['BANNER_FRIENDS_ANDROID']!,
      iosAdId: dotenv.env['BANNER_FRIENDS_IOS']!,
    );
  }

  // 친구 목록
  Widget _buildFriendsList(
    double width,
    FriendProfilesState friendProfilesState,
  ) {
    friendProfilesState.friendList.sort(
      (a, b) => a.displayName.compareTo(b.displayName),
    );
    if (!friendProfilesState.isLoading &&
        friendProfilesState.friendList.isEmpty) {
      return Expanded(child: Center(child: Text('친구를 추가해보세요!')));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: friendProfilesState.friendList.length,

      itemBuilder:
          (context, index) =>
              _buildFriendItem(friendProfilesState.friendList[index], width),
    );
  }

  // 친구 항목
  Widget _buildFriendItem(FriendProfile friendProfile, double width) {
    return InkWell(
      onTap: () => _toFriendsDetail(friendProfile),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.03,
          vertical: width * 0.02,
        ),
        child: Row(
          children: [
            ProfileImageView(
              size: width * 0.15,
              profileImageUrl: friendProfile.profileImageUrl!,
            ),
            SizedBox(width: width * 0.035),
            Expanded(child: _buildFriendInfo(friendProfile)),
            _buildMissionBadge(friendProfile.progressMissions, width),
          ],
        ),
      ),
    );
  }

  // 친구 프로필 사진, 이름, 상태메시지
  Widget _buildFriendInfo(FriendProfile friendProfile) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          friendProfile.displayName,
          style: Theme.of(context).textTheme.bodyMedium,
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
  Widget _buildMissionBadge(int count, double width) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        SvgPicture.asset(
          'assets/icons/star.svg',
          width: width * 0.08,
          colorFilter: ColorFilter.mode(
            count == 0 ? Colors.grey.shade400 : kYellow,
            BlendMode.srcIn,
          ),
        ),
        Positioned(
          child: Text(
            count.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: width * 0.045),
          ),
        ),
      ],
    );
  }
}
