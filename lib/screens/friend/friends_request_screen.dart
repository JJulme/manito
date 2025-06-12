import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class FriendsRequestScreen extends StatefulWidget {
  const FriendsRequestScreen({super.key});

  @override
  State<FriendsRequestScreen> createState() => _FriendsRequestScreenState();
}

class _FriendsRequestScreenState extends State<FriendsRequestScreen> {
  final FriendsController friendsController = Get.find<FriendsController>();
  final FriendRequestController _controller = Get.put(
    FriendRequestController(),
  );

  // Constants for responsive design
  static const double _titleSpacingRatio = 0.02;
  static const double _horizontalPaddingRatio = 0.05;
  static const double _verticalPaddingRatio = 0.03;
  static const double _profileImageRatio = 0.2;
  static const double _spacingRatio = 0.05;
  static const double _actionButtonSizeRatio = 0.08;

  // Constants for colors
  static const Color _acceptColor = Colors.green;
  static const Color _rejectColor = Colors.red;

  /// 수락 함수
  Future<void> _acceptRequest(String senderId) async {
    String result = await _controller.acceptFriendRequest(senderId);
    // 요청 목록 다시 가져오기
    _controller.fetchFriendRequest();
    // 친구 목록 다시 가져오기
    friendsController.fetchFriendList();
    if (!mounted) return;
    customSnackbar(
      title: context.tr('friends_request_screen.snack_title'),
      message: context.tr('friends_request_screen.$result'),
    );
  }

  /// 거절 함수
  Future<void> _rejectRequest(String senderId) async {
    String result = await _controller.rejectFriendRequest(senderId);
    _controller.fetchFriendRequest();
    if (!mounted) return;
    customSnackbar(
      title: '알림',
      message: context.tr('friends_request_screen.$result'),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return Scaffold(
      appBar: _buildAppBar(width),
      body: SafeArea(
        child: _buildBody(),
        // child: Obx(() {
        //   // 로딩중
        //   if (_controller.requestLoading.value) {
        //     return Center(child: CircularProgressIndicator());
        //   }
        //   // 요청 목록이 없는 경우
        //   else if (_controller.requestUserList.isEmpty) {
        //     return Center(
        //       child:
        //           Text(
        //             'friends_request_screen.empty_request',
        //             style: Get.textTheme.bodyMedium,
        //           ).tr(),
        //     );
        //   }
        //   // 요청 목록이 있는 경우
        //   else {
        //     return ListView.builder(
        //       itemCount: _controller.requestUserList.length,
        //       itemBuilder: (context, index) {
        //         final userProfile = _controller.requestUserList[index];

        //         return Column(
        //           children: [
        //             Container(
        //               padding: EdgeInsets.symmetric(
        //                 horizontal: 0.05 * width,
        //                 vertical: 0.03 * width,
        //               ),
        //               child: Row(
        //                 mainAxisSize: MainAxisSize.max,
        //                 mainAxisAlignment: MainAxisAlignment.start,
        //                 children: [
        //                   // 프로필 이미지
        //                   profileImageOrDefault(
        //                     userProfile.profileImageUrl!,
        //                     0.2 * width,
        //                   ),
        //                   SizedBox(width: 0.05 * width),
        //                   Expanded(
        //                     child: Column(
        //                       mainAxisAlignment: MainAxisAlignment.center,
        //                       crossAxisAlignment: CrossAxisAlignment.start,
        //                       children: [
        //                         // 이름
        //                         Text(
        //                           userProfile.nickname,
        //                           style: Get.textTheme.bodyMedium,
        //                           overflow: TextOverflow.ellipsis,
        //                         ),
        //                         // 상태 메시지
        //                         Text(
        //                           userProfile.statusMessage,
        //                           style: Get.textTheme.bodySmall,
        //                           overflow: TextOverflow.ellipsis,
        //                         ),
        //                       ],
        //                     ),
        //                   ),

        //                   // 수락 버튼
        //                   IconButton(
        //                     icon: Icon(
        //                       Icons.check_rounded,
        //                       color: Colors.green,
        //                       size: 0.08 * width,
        //                     ),
        //                     onPressed: () => _acceptRequest(userProfile.id),
        //                   ),
        //                   // 거절 버튼
        //                   IconButton(
        //                     icon: Icon(
        //                       Icons.close_rounded,
        //                       color: Colors.red,
        //                       size: 0.08 * width,
        //                     ),
        //                     onPressed: () => _rejectRequest(userProfile.id),
        //                   ),
        //                 ],
        //               ),
        //             ),
        //           ],
        //         );
        //       },
        //     );
        //   }
        // }),
      ),
    );
  }

  // 앱바
  PreferredSizeWidget _buildAppBar(double width) {
    return AppBar(
      centerTitle: false,
      titleSpacing: _titleSpacingRatio * width,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Get.back(),
      ),
      title:
          Text(
            'friends_request_screen.title',
            style: Get.textTheme.headlineMedium,
          ).tr(),
    );
  }

  // 바디
  Widget _buildBody() {
    return Obx(() {
      if (_controller.requestLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_controller.requestUserList.isEmpty) {
        return Center(
          child:
              Text(
                'friends_request_screen.empty_request',
                style: Get.textTheme.bodyMedium,
              ).tr(),
        );
      }

      return _buildRequestList();
    });
  }

  // 친구 요청 리스트
  Widget _buildRequestList() {
    return ListView.builder(
      itemCount: _controller.requestUserList.length,
      itemBuilder: (context, index) {
        final userProfile = _controller.requestUserList[index];
        return _buildRequestItem(userProfile);
      },
    );
  }

  // 친구 요청 아이템
  Widget _buildRequestItem(dynamic userProfile) {
    final width = Get.width;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _horizontalPaddingRatio * width,
        vertical: _verticalPaddingRatio * width,
      ),
      child: Row(
        children: [
          _buildProfileImage(userProfile, width),
          SizedBox(width: _spacingRatio * width),
          _buildUserInfo(userProfile),
          _buildActionButtons(userProfile, width),
        ],
      ),
    );
  }

  // 프로필 이미지
  Widget _buildProfileImage(dynamic userProfile, double width) {
    return profileImageOrDefault(
      userProfile.profileImageUrl ?? '',
      _profileImageRatio * width,
    );
  }

  // 닉네임, 상태메시지
  Widget _buildUserInfo(dynamic userProfile) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userProfile.nickname ?? '',
            style: Get.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
          if (userProfile.statusMessage?.isNotEmpty ?? false)
            Text(
              userProfile.statusMessage!,
              style: Get.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  // 수락 거절 Row
  Widget _buildActionButtons(dynamic userProfile, double width) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAcceptButton(userProfile, width),
        _buildRejectButton(userProfile, width),
      ],
    );
  }

  // 수락 버튼
  Widget _buildAcceptButton(dynamic userProfile, double width) {
    return IconButton(
      icon: Icon(
        Icons.check_rounded,
        color: _acceptColor,
        size: _actionButtonSizeRatio * width,
      ),
      onPressed: () => _acceptRequest(userProfile.id),
    );
  }

  // 거절 버튼
  Widget _buildRejectButton(dynamic userProfile, double width) {
    return IconButton(
      icon: Icon(
        Icons.close_rounded,
        color: _rejectColor,
        size: _actionButtonSizeRatio * width,
      ),
      onPressed: () => _rejectRequest(userProfile.id),
    );
  }
}
