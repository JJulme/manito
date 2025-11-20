import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:manito/features/friends/friends.dart';
import 'package:manito/features/friends/friends_provider.dart';
import 'package:manito/features/profiles/profile.dart';
import 'package:manito/main.dart';
import 'package:manito/share/common_dialog.dart';
import 'package:manito/share/sub_appbar.dart';
import 'package:manito/widgets/profile_image_view.dart';

class FriendsBlacklistScreen extends ConsumerStatefulWidget {
  const FriendsBlacklistScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FriendsBlacklistScreenState();
}

class _FriendsBlacklistScreenState
    extends ConsumerState<FriendsBlacklistScreen> {
  // 목록 새로고침
  Future<void> _handleRefresh() async {
    await ref.read(blacklistProvider.notifier).refresh();
  }

  // 차단 해제
  Future<void> _handleUnblackUser(String blackUserId) async {
    final result = await DialogHelper.showConfirmDialog(
      context,
      message: context.tr("friends_blacklist_screen.dialog_message"),
    );
    if (result == true) {
      ref.read(blacklistProvider.notifier).unblockUser(blackUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blackListAsync = ref.watch(blacklistProvider);
    return Scaffold(
      appBar: SubAppbar(
        title:
            Text(
              'friends_blacklist_screen.title',
              style: Theme.of(context).textTheme.headlineMedium,
            ).tr(),
      ),
      body: blackListAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (state) {
          return RefreshIndicator(
            onRefresh: () => _handleRefresh(),
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: _buildBody(state),
            ),
          );
        },
      ),
    );
  }

  // 바디
  Widget _buildBody(BlacklistState state) {
    if (state.blackList.isEmpty) {
      return Container(
        width: width,
        height: width,
        alignment: Alignment.center,
        child:
            Text(
              'friends_blacklist_screen.empty_blacklist',
              style: Theme.of(context).textTheme.bodyMedium,
            ).tr(),
      );
    } else {
      return ListView.builder(
        itemCount: state.blackList.length,
        itemBuilder: (context, index) {
          final userProfile = state.blackList[index];
          return _buildBlacklistItem(userProfile);
        },
      );
    }
  }

  // 블랙리스트 아이템
  Widget _buildBlacklistItem(UserProfile userProfile) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: width * 0.02,
        horizontal: width * 0.04,
      ),
      child: Row(
        children: [
          ProfileImageView(
            size: width * 0.2,
            profileImageUrl: userProfile.profileImageUrl!,
          ),
          SizedBox(width: width * 0.04),
          Expanded(
            child: Text(
              userProfile.nickname,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          OutlinedButton(
            child: Text("friends_blacklist_screen.unblack_btn").tr(),
            onPressed: () => _handleUnblackUser(userProfile.id),
          ),
        ],
      ),
    );
  }
}
