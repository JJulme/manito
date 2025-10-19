import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features/auth/auth_provider.dart';
import 'package:manito/features/fcm/fcm_provider.dart';
import 'package:manito/features/manito/manito_provider.dart';
import 'package:manito/features/missions/mission_provider.dart';
import 'package:manito/features/posts/post_provider.dart';
import 'package:manito/features/profiles/profile_provider.dart';
import 'package:manito/share/common_dialog.dart';
import 'package:manito/share/custom_toast.dart';
import 'package:manito/share/sub_appbar.dart';
import 'package:restart_app/restart_app.dart';

class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});
  static const String _contactEmail = 'manito.ask@gmail.com';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double width = MediaQuery.of(context).size.width;
    final notifier = ref.read(authNotifierProvider.notifier);

    /// 모든 사용자 관련 프로바이더 무효화
    void invalidateAllUserProviders() {
      // 인증 관련
      ref.invalidate(supabaseProvider);
      ref.invalidate(currentUserProvider);
      ref.invalidate(authStateChangesProvider);

      // 사용자 정보 관련
      ref.invalidate(fcmListenerProvider);
      ref.invalidate(userProfileProvider);
      ref.invalidate(friendProfilesProvider);

      // 데이터 관련
      ref.invalidate(missionListProvider);
      ref.invalidate(manitoListProvider);
      ref.invalidate(postsProvider);
    }

    // 로그아웃
    void showLogoutDialog() async {
      final result = await DialogHelper.showConfirmDialog(
        context,
        message: context.tr('setting_screen.logout_dialog_message'),
      );
      if (result == true) {
        invalidateAllUserProviders();
        notifier.signOut();
      }
    }

    // 언어 설정
    String getLanguageDisplayName(Locale locale) {
      switch (locale.languageCode) {
        case 'ko':
          return '한국어';
        case 'en':
          return 'English';
        // 다른 언어가 있다면 추가
        default:
          return locale.languageCode; // 기본적으로는 언어 코드를 표시
      }
    }

    void showLanguageSelectionDialog() {
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
                        getLanguageDisplayName(locale),
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
                    Text(
                      "setting_screen.dialog_cancel",
                    ).tr(), // '취소' 텍스트도 다국어 처리
              ),
            ],
          );
        },
      );
    }

    // 이메일 복사
    void copyEmailToClipboard() {
      Clipboard.setData(const ClipboardData(text: _contactEmail));

      if (Platform.isIOS) {
        customToast(
          width: width,
          msg: context.tr("setting_screen.copy_snack_message"),
        );
      }
    }

    // 계정 삭제
    void showDeleteAccountDialog() async {
      final result = await DialogHelper.showWarningDialog(
        context,
        message: context.tr('setting_screen.delete_account_dialog_message'),
      );
      if (result == true) {
        invalidateAllUserProviders();
        notifier.deleteUser();
      }
    }

    return Scaffold(
      appBar: SubAppbar(
        width: width,
        title:
            Text(
              'setting_screen.title',
              style: Theme.of(context).textTheme.headlineLarge,
            ).tr(),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            // 로그아웃
            _buildSettingItem(
              width: width,
              context: context,
              icon: Icons.logout_outlined,
              title: context.tr('setting_screen.logout'),
              onTap: showLogoutDialog,
            ),
            // // 언어변경
            // _buildSettingItem(
            //   width: width,
            //   context: context,
            //   icon: Icons.language_rounded,
            //   title: context.tr('setting_screen.language'),
            //   onTap: () => showLanguageSelectionDialog(),
            // ),
            // 문의하기
            _buildSettingItem(
              width: width,
              context: context,
              icon: Icons.mail_outline_rounded,
              title: context.tr('setting_screen.contact'),
              subtitle: _contactEmail,
              onTap: copyEmailToClipboard,
            ),
            // 계정삭제
            _buildSettingItem(
              width: width,
              context: context,
              icon: Icons.disabled_by_default_rounded,
              title: context.tr('setting_screen.delete_account'),
              onTap: showDeleteAccountDialog,
            ),
          ],
        ),
      ),
    );
  }

  // 목록 아이템
  Widget _buildSettingItem({
    required double width,
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: width * 0.2,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
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
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
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
