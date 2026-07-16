import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/widget/common_error_widget.dart';
import 'package:manito/core/widget/common_loading_widget.dart';
import 'package:manito/core/widget/profile_image_view.dart';
import 'package:manito/core/widget/sub_appbar.dart';
import 'package:manito/features_new/friends/presentation/providers/blocked_users_provider.dart';
import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';
import 'package:manito/main.dart';
import 'package:manito/core/widget/common_dialog.dart';

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  // 목록 새로고침
  Future<void> _handleRefresh() async {
    await ref.read(blockedUsersProvider.notifier).refresh();
  }

  // 차단 해제
  Future<void> _handleUnblockUser(String blockUserId) async {
    final result = await DialogHelper.showConfirmDialog(
      context,
      title: context.tr("friends_blacklist_screen.dialog_title"),
      message: context.tr("friends_blacklist_screen.dialog_message"),
    );
    if (result == true) {
      ref.read(blockedUsersProvider.notifier).unblock(blockUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockedAsync = ref.watch(blockedUsersProvider);
    return Scaffold(
      appBar: SubAppbar(
        title:
            Text(
              'friends_blacklist_screen.title',
              style: Theme.of(context).textTheme.headlineSmall,
            ).tr(),
      ),
      body: blockedAsync.when(
        loading: () => CommonLoadingWidget(),
        error:
            (error, stackTrace) => RefreshIndicator(
              onRefresh: _handleRefresh,
              child: CommonErrorWidget(error: error),
            ),
        data: (blockedList) => _buildBlockedlist(blockedList),
      ),
    );
  }

  // 바디
  Widget _buildBlockedlist(List<UserEntity> blockedList) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child:
                  blockedList.isEmpty
                      ? Container(
                        width: width,
                        height: width,
                        alignment: Alignment.center,
                        child:
                            Text(
                              'friends_blacklist_screen.empty_blacklist',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ).tr(),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: blockedList.length,
                        itemBuilder: (context, index) {
                          final userProfile = blockedList[index];
                          return _buildBlockItem(userProfile);
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  // 블랙리스트 아이템
  Widget _buildBlockItem(UserEntity userProfile) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: width * 0.02,
        horizontal: width * 0.04,
      ),
      child: Row(
        children: [
          ProfileImageView(
            size: width * 0.2,
            profileImageUrl: userProfile.profileImageUrl,
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
            onPressed: () => _handleUnblockUser(userProfile.id),
          ),
        ],
      ),
    );
  }
}
