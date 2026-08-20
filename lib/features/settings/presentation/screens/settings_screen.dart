import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/theme/theme_provider.dart';
import 'package:manito/features/auth/presentation/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String _contactEmail = 'manito.ask@gmail.com';

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃', style: AppTypography.headlineMd),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).signOut();
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 탈퇴', style: AppTypography.headlineMd),
        content: const Text(
          '회원 탈퇴 시 모든 친구 관계, 마니또 기록, 프로필 정보가 영구 삭제되며 복구할 수 없습니다.\n\n정말 탈퇴하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).deleteUser();
            },
            child: const Text('탈퇴하기'),
          ),
        ],
      ),
    );
  }

  void _copyEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: _contactEmail));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('문의 이메일($contactEmail)이 복사되었습니다.'),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static const String contactEmail = _contactEmail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('환경설정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Section 1: 일반 설정
          const Text('일반 설정', style: AppTypography.labelMd),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_medium_rounded, color: AppColors.textPrimary),
                  title: const Text('테마 모드', style: AppTypography.titleSmall),
                  subtitle: Text(
                    themeMode == ThemeMode.light
                        ? '라이트 모드'
                        : themeMode == ThemeMode.dark
                            ? '다크 모드'
                            : '시스템 설정 동기화',
                    style: AppTypography.bodySm,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textDisabled),
                  onTap: () {
                    if (themeMode == ThemeMode.light) {
                      ref.read(themeProvider.notifier).state = ThemeMode.dark;
                    } else if (themeMode == ThemeMode.dark) {
                      ref.read(themeProvider.notifier).state = ThemeMode.system;
                    } else {
                      ref.read(themeProvider.notifier).state = ThemeMode.light;
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppColors.textPrimary),
                  title: const Text('언어 설정 (Language)', style: AppTypography.titleSmall),
                  subtitle: Text(
                    context.locale.languageCode == 'ko' ? '한국어 (Korean)' : 'English',
                    style: AppTypography.bodySm,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textDisabled),
                  onTap: () async {
                    if (context.locale.languageCode == 'ko') {
                      await context.setLocale(const Locale('en', 'US'));
                    } else {
                      await context.setLocale(const Locale('ko', 'KR'));
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: 고객지원
          const Text('고객지원 및 문의', style: AppTypography.labelMd),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.mail_outline_rounded, color: AppColors.textPrimary),
                  title: const Text('개발팀 문의하기', style: AppTypography.titleSmall),
                  subtitle: const Text(_contactEmail, style: AppTypography.bodySm),
                  trailing: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textSecondary),
                  onTap: () => _copyEmail(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.textPrimary),
                  title: const Text('앱 버전', style: AppTypography.titleSmall),
                  subtitle: const Text('2.1.1 (최신 버전)', style: AppTypography.bodySm),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: 계정 관리
          const Text('계정 관리', style: AppTypography.labelMd),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.textPrimary),
                  title: const Text('로그아웃', style: AppTypography.titleSmall),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textDisabled),
                  onTap: () => _showLogoutDialog(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.person_remove_outlined, color: AppColors.statusRed),
                  title: Text(
                    '회원 탈퇴',
                    style: AppTypography.titleSmall.copyWith(color: AppColors.statusRed),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textDisabled),
                  onTap: () => _showDeleteAccountDialog(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
