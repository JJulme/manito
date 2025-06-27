import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/auth_controller.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:restart_app/restart_app.dart';

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

  // 언어 설정
  void _showLanguageSelectionDialog(BuildContext context) {
    // 이 값은 다이얼로그 내 라디오 버튼의 초기 선택 상태를 결정합니다.
    String currentLanguageCode = context.locale.languageCode;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // 다이얼로그 빌더의 context
        return AlertDialog(
          title: Text("setting_screen.dialog_title").tr(),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                context.supportedLocales.map((locale) {
                  // 지원되는 각 언어(Locale)에 대해 RadioListTile 생성
                  return RadioListTile<String>(
                    title: Text(
                      _getLanguageDisplayName(locale.languageCode),
                    ), // 언어 이름 표시 (예: 한국어, English)
                    value: locale.languageCode, // 라디오 버튼의 값 (언어 코드)
                    groupValue: currentLanguageCode, // 현재 선택된 라디오 버튼의 값
                    onChanged: (String? newValue) async {
                      if (newValue != null) {
                        // 새로운 언어로 변경
                        await context.setLocale(
                          Locale(locale.languageCode, locale.countryCode),
                        );
                        // 변경된 언어를 서버에 전송하는 로직이 있다면 여기서 호출
                        // await _apiService.sendLanguageToServer(newValue, locale.countryCode);
                        // 앱 재부팅
                        if (!context.mounted) return;
                        Restart.restartApp(
                          notificationTitle: context.tr(
                            "setting_screen.restart_title",
                          ),
                          notificationBody: context.tr(
                            "setting_screen.restart_body",
                          ),
                        );

                        // 다이얼로그 닫기
                        if (dialogContext.mounted) {
                          // mounted 체크 중요!
                          Navigator.of(dialogContext).pop();
                        }
                      }
                    },
                  );
                }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (dialogContext.mounted) {
                  // mounted 체크 중요!
                  Navigator.of(dialogContext).pop(); // 다이얼로그 닫기
                }
              },
              child:
                  Text("setting_screen.dialog_cancel").tr(), // '취소' 텍스트도 다국어 처리
            ),
          ],
        );
      },
    );
  }

  String _getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      // 다른 언어가 있다면 추가
      default:
        return languageCode; // 기본적으로는 언어 코드를 표시
    }
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
            // 친구 목록 새로고침
            _buildSettingItem(
              icon: Icons.refresh,
              title: context.tr('setting_screen.friends_refresh'),
              onTap: _refreshFriendsList,
            ),
            // 로그아웃
            _buildSettingItem(
              icon: Icons.logout_outlined,
              title: context.tr('setting_screen.logout'),
              onTap: _showLogoutDialog,
            ),
            // // 언어 변경
            // _buildSettingItem(
            //   icon: Icons.language_rounded,
            //   title: context.tr('setting_screen.language'),
            //   onTap: () => _showLanguageSelectionDialog(context),
            // ),
            // 문의하기
            _buildSettingItem(
              icon: Icons.mail_outline_rounded,
              title: context.tr('setting_screen.contact'),
              subtitle: _contactEmail,
              onTap: _copyEmailToClipboard,
            ),
            // 계정 삭제
            _buildSettingItem(
              icon: Icons.disabled_by_default_rounded,
              title: context.tr('setting_screen.delete_account'),
              onTap: _showDeleteAccountDialog,
            ),
          ],
        ),
      ),
    );
  }

  // 앱바
  AppBar _buildAppBar() {
    final width = Get.width;
    return AppBar(
      centerTitle: false,
      titleSpacing: _titleSpacing * width,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Get.back(),
      ),
      title:
          Text('setting_screen.title', style: Get.textTheme.headlineLarge).tr(),
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
