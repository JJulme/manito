import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/widget/common_error_widget.dart';
import 'package:manito/core/widget/common_loading_widget.dart';
import 'package:manito/core/widget/profile_image_view.dart';
import 'package:manito/features/theme/theme.dart';
import 'package:manito/features_new/friends/presentation/providers/friend_requests_provider.dart';
import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';
import 'package:manito/main.dart';
import 'package:manito/core/widget/common_dialog.dart';
import 'package:manito/share/sub_appbar.dart';

class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen> {
  // 새로고침
  Future<void> _handleRefeash() async {
    await ref.read(friendRequestsProvider.notifier).refresh();
  }

  // 수락 다이얼로그
  Future<void> _handleAcceptRequest(String senderId) async {
    final result = await DialogHelper.showConfirmDialog(
      context,
      title: '친구 수락',
      message: '친구 요청을 수락하시겠습니까?',
    );
    if (result == true) {
      ref.read(friendRequestsProvider.notifier).acceptRequest(senderId);
    }
  }

  // 거절 다이얼로그
  Future<void> _handleRejectRequest(String senderId) async {
    final result = await DialogHelper.showConfirmDialog(
      context,
      title: '친구 거절',
      message: '친구 요청을 거절하시겠습니까?',
    );
    if (result == true) {
      ref.read(friendRequestsProvider.notifier).rejectRequest(senderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(friendRequestsProvider);
    return Scaffold(
      appBar: SubAppbar(
        title:
            Text(
              'friends_request_screen.title',
              style: Theme.of(context).textTheme.headlineSmall,
            ).tr(),
      ),
      body: requestsAsync.when(
        loading: () => CommonLoadingWidget(),
        error:
            (error, stackTrace) => RefreshIndicator(
              onRefresh: _handleRefeash,
              child: CommonErrorWidget(error: error),
            ),
        data: (requestList) => _buildRequestList(requestList),
      ),
    );
  }

  Widget _buildRequestList(List<UserEntity> requestList) {
    return RefreshIndicator(
      onRefresh: _handleRefeash,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child:
                  requestList.isEmpty
                      ? Container(
                        width: width,
                        height: width,
                        alignment: Alignment.center,
                        child:
                            Text(
                              'friends_request_screen.empty_request',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ).tr(),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: requestList.length,
                        itemBuilder: (context, index) {
                          final userProfile = requestList[index];
                          return _buildRequestItem(userProfile);
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  // 친구 신청 아이템
  Widget _buildRequestItem(UserEntity userProfile) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: width * 0.03,
        horizontal: width * 0.05,
      ),
      child: Row(
        children: [
          ProfileImageView(
            size: width * 0.2,
            profileImageUrl: userProfile.profileImageUrl,
          ),
          SizedBox(width: width * 0.05),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfile.nickname,
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                if (userProfile.statusMessage?.isNotEmpty ?? false)
                  Text(
                    userProfile.statusMessage!,
                    style: Theme.of(context).textTheme.labelSmall,
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
  Widget _buildActionButtons(UserEntity userProfile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAcceptButton(userProfile),
        _buildRejectButton(userProfile),
      ],
    );
  }

  // 수락 버튼
  Widget _buildAcceptButton(UserEntity userProfile) {
    return IconButton(
      icon: Icon(Icons.check_rounded, color: kSuccess, size: width * 0.08),
      onPressed: () => _handleAcceptRequest(userProfile.id),
    );
  }

  // 거절 버튼
  Widget _buildRejectButton(UserEntity userProfile) {
    return IconButton(
      icon: Icon(Icons.close_rounded, color: kDeepOrange, size: width * 0.08),
      onPressed: () => _handleRejectRequest(userProfile.id),
    );
  }
}
