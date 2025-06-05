import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/auth_controller.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';

class SettingScreen extends StatelessWidget {
  SettingScreen({super.key});
  final _authController = Get.put(AuthController());
  final FriendsController _friendsController = Get.find<FriendsController>();

  // Constants
  static const double _itemHeight = 0.2;
  static const double _horizontalPadding = 0.05;
  static const double _titleSpacing = 0.02;
  static const String _contactEmail = 'manito.ask@gmail.com';

  // 친구 목록 새로고침
  Future<void> _refreshFriendsList() async {
    _friendsController.isLoading.value = true;
    try {
      await Future.wait([
        _friendsController.getProfile(),
        _friendsController.fetchFriendList(),
      ]);
    } finally {
      _friendsController.isLoading.value = false;
    }
  }

  // 로그아웃
  void _showLogoutDialog() {
    kDefaultDialog(
      '로그아웃',
      '로그아웃 하시겠습니까?',
      onYesPressed: () => _authController.logout(),
    );
  }

  // 이메일 복사
  void _copyEmailToClipboard() {
    Clipboard.setData(const ClipboardData(text: _contactEmail));

    if (GetPlatform.isIOS) {
      customSnackbar(title: '복사 완료', message: '이메일 주소가 복사 되었습니다.');
    }
  }

  // 계정 삭제
  void _showDeleteAccountDialog() {
    kDefaultDialog(
      '계정 삭제',
      '계정을 삭제하면 복구 할 수 없습니다.',
      onYesPressed: () async {
        await _authController.deleteUser();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: ListView(
          children: [
            _buildSettingItem(
              icon: Icons.refresh,
              title: '친구목록 새로고침',
              onTap: _refreshFriendsList,
            ),
            _buildSettingItem(
              icon: Icons.logout_outlined,
              title: '로그아웃',
              onTap: _showLogoutDialog,
            ),
            _buildSettingItem(
              icon: Icons.mail_outline_rounded,
              title: '문의하기',
              subtitle: _contactEmail,
              onTap: _copyEmailToClipboard,
            ),
            _buildSettingItem(
              icon: Icons.disabled_by_default_rounded,
              title: '계정 삭제',
              onTap: _showDeleteAccountDialog,
            ),
          ],
        ),
      ),
      // body: SafeArea(
      //   child: ListView(
      //     children: [
      //       // 친구목록 새로고침
      //       Container(
      //         height: 0.18 * width,
      //         alignment: Alignment.center,
      //         child: ListTile(
      //           contentPadding: EdgeInsets.symmetric(horizontal: 0.05 * width),
      //           leading: Icon(Icons.refresh),
      //           title: Text('친구목록 새로고침'),
      //           onTap: () {
      //             _friendsController.isLoading.value = true;
      //             _friendsController.getProfile();
      //             _friendsController.fetchFriendList();
      //             _friendsController.isLoading.value = false;
      //           },
      //         ),
      //       ),
      //       // 로그아웃
      //       Container(
      //         height: 0.18 * width,
      //         alignment: Alignment.center,
      //         child: ListTile(
      //           contentPadding: EdgeInsets.symmetric(horizontal: 0.05 * width),
      //           leading: Icon(Icons.logout_outlined),
      //           title: Text('로그아웃'),
      //           // onTap: _authController.logout,
      //           onTap: () {
      //             kDefaultDialog(
      //               '로그아웃',
      //               '로그아웃 하시겠습니까?',
      //               onYesPressed: () => _authController.logout(),
      //             );
      //           },
      //         ),
      //       ),
      //       // 문의하기
      //       Container(
      //         height: 0.18 * width,
      //         alignment: Alignment.center,
      //         child: ListTile(
      //           contentPadding: EdgeInsets.symmetric(horizontal: 0.05 * width),
      //           leading: Icon(Icons.mail_outline_rounded),
      //           title: Text('문의하기'),
      //           subtitle: Text(
      //             'manito.ask@gmail.com',
      //             style: Get.textTheme.labelLarge,
      //           ),
      //           onTap: () {
      //             Clipboard.setData(
      //               ClipboardData(text: 'manito.ask@gmail.com'),
      //             );
      //             if (GetPlatform.isIOS) {
      //               customSnackbar(
      //                 title: '복사 완료',
      //                 message: '이메일 주소가 복사 되었습니다.',
      //               );
      //             }
      //           },
      //         ),
      //       ),

      //       // 계정 삭제
      //       Container(
      //         height: 0.18 * width,
      //         alignment: Alignment.center,
      //         child: ListTile(
      //           contentPadding: EdgeInsets.symmetric(horizontal: 0.05 * width),
      //           leading: Icon(Icons.disabled_by_default_outlined),
      //           title: Text('계정 삭제'),
      //           onTap: () {
      //             kDefaultDialog(
      //               '계정 삭제',
      //               '계정을 삭제하면 복구 할 수 없습니다.',
      //               onYesPressed: () async {
      //                 await _authController.deleteUser();
      //               },
      //             );
      //           },
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }

  // 앱바
  PreferredSizeWidget _buildAppBar() {
    final width = Get.width;
    return AppBar(
      centerTitle: false,
      titleSpacing: _titleSpacing * width,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Get.back(),
      ),
      title: Text('설정', style: Get.textTheme.headlineLarge),
    );
  }

  // 목록 아이템
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final width = Get.width;

    return SizedBox(
      height: _itemHeight * width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _horizontalPadding * width,
            ),
            child: Row(
              children: [
                Icon(icon),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title),
                      if (subtitle != null) ...[
                        SizedBox(height: 4),
                        Text(subtitle, style: Get.textTheme.labelLarge),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
