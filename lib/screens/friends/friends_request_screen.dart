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

class FriendsRequestScreen extends ConsumerStatefulWidget {
  const FriendsRequestScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FriendsRequestScreenState();
}

class _FriendsRequestScreenState extends ConsumerState<FriendsRequestScreen> {
  // Constants for colors
  static const Color _acceptColor = Colors.green;
  static const Color _rejectColor = Colors.red;

  // 새로고침
  Future<void> _handleRefeash() async {
    await ref.read(friendRequestProvider.notifier).refresh();
  }

  // 수락 다이얼로그
  Future<void> _handleAcceptRequest(String senderId) async {
    final result = await DialogHelper.showConfirmDialog(
      context,
      message: '친구 요청을 수락하시겠습니까?',
    );
    if (result == true) {
      ref.read(friendRequestProvider.notifier).acceptFriendRequest(senderId);
    }
  }

  // 거절 다이얼로그
  Future<void> _handleRejectRequest(String senderId) async {
    final result = await DialogHelper.showConfirmDialog(
      context,
      message: '친구 요청을 거절하시겠습니까?',
    );
    if (result == true) {
      ref.read(friendRequestProvider.notifier).rejectFriendRequest(senderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(friendRequestProvider);
    return Scaffold(
      appBar: SubAppbar(
        title:
            Text(
              'friends_request_screen.title',
              style: Theme.of(context).textTheme.headlineMedium,
            ).tr(),
      ),
      body: requestAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (state) {
          return RefreshIndicator(
            onRefresh: () => _handleRefeash(),
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
  Widget _buildBody(FriendRequestState state) {
    // 친구 요청이 없을 때
    if (state.requestUserList.isEmpty) {
      return Container(
        width: width,
        height: width,
        alignment: Alignment.center,
        child:
            Text(
              'friends_request_screen.empty_request',
              style: Theme.of(context).textTheme.bodyMedium,
            ).tr(),
      );
    }
    // 친구요청이 있을 때
    else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.requestUserList.length,
        itemBuilder: (context, index) {
          final userProfile = state.requestUserList[index];
          return _buildRequestItem(userProfile);
        },
      );
    }
  }

  // 친구 신청 아이템
  Widget _buildRequestItem(UserProfile userProfile) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: width * 0.03,
        horizontal: width * 0.05,
      ),
      child: Row(
        children: [
          ProfileImageView(
            size: width * 0.2,
            profileImageUrl: userProfile.profileImageUrl!,
          ),
          SizedBox(width: width * 0.05),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfile.nickname,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                if (userProfile.statusMessage?.isNotEmpty ?? false)
                  Text(
                    userProfile.statusMessage!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          _buildActionButtons(userProfile),
        ],
      ),
    );
  }

  // 수락 거절 Row
  Widget _buildActionButtons(UserProfile userProfile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAcceptButton(userProfile),
        _buildRejectButton(userProfile),
      ],
    );
  }

  // 수락 버튼
  Widget _buildAcceptButton(UserProfile userProfile) {
    return IconButton(
      icon: Icon(Icons.check_rounded, color: _acceptColor, size: width * 0.08),
      onPressed: () => _handleAcceptRequest(userProfile.id),
    );
  }

  // 거절 버튼
  Widget _buildRejectButton(UserProfile userProfile) {
    return IconButton(
      icon: Icon(Icons.close_rounded, color: _rejectColor, size: width * 0.08),
      onPressed: () => _handleRejectRequest(userProfile.id),
    );
  }
}
