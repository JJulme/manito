import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Future<void> _unblackUser(String blackUserId) async {
    final result = await DialogHelper.showConfirmDialog(
      context,
      message: context.tr("friends_blacklist_screen.dialog_message"),
    );
    if (result == true) {
      ref.read(blacklistProvider.notifier).unblackUser(blackUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blacklistProvider);
    return Scaffold(
      appBar: SubAppbar(
        title:
            Text(
              'friends_blacklist_screen.title',
              style: Theme.of(context).textTheme.headlineMedium,
            ).tr(),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(BlacklistState state) {
    if (state.isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (state.error != null) {
      return Center(child: Text(state.error.toString()));
    } else if (!state.isLoading && state.blackList.isEmpty) {
      return Center(
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
            onPressed: () => _unblackUser(userProfile.id),
          ),
        ],
      ),
    );
  }
}
