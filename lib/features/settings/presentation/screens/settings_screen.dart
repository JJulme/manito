import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/theme/theme_provider.dart';
import 'package:manito/core/analytics/analytics_event.dart';
import 'package:manito/core/analytics/analytics_service.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features/auth/presentation/auth_provider.dart';
import 'package:manito/core/constants/app_constants.dart';
import 'package:manito/i18n/strings.g.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
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
      builder:
          (ctx) => AlertDialog(
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
    Clipboard.setData(const ClipboardData(text: AppConstants.contactEmail));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('문의 이메일(${AppConstants.contactEmail})이 복사되었습니다.'),
        backgroundColor: AppColors.textPrimaryOf(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showThemeModePicker(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(themeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).cardTheme.color ??
                  AppColors.cardOf(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderOf(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '테마 모드 설정',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimaryOf(context),
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildThemeOptionTile(
                  context: ctx,
                  title: '라이트 모드',
                  subtitle: '밝고 산뜻한 기본 테마',
                  icon: Icons.light_mode_outlined,
                  isSelected: currentTheme == ThemeMode.light,
                  onTap: () {
                    ref
                        .read(analyticsServiceProvider)
                        .logEvent(
                          AnalyticsEvent.themeChange,
                          screenName: 'SettingsScreen',
                          properties: {'mode': 'light'},
                        );
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
                    Navigator.pop(ctx);
                  },
                ),
                _buildThemeOptionTile(
                  context: ctx,
                  title: '다크 모드',
                  subtitle: '어두운 환경에서 눈이 편안한 테마',
                  icon: Icons.dark_mode_outlined,
                  isSelected: currentTheme == ThemeMode.dark,
                  onTap: () {
                    ref
                        .read(analyticsServiceProvider)
                        .logEvent(
                          AnalyticsEvent.themeChange,
                          screenName: 'SettingsScreen',
                          properties: {'mode': 'dark'},
                        );
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
                    Navigator.pop(ctx);
                  },
                ),
                _buildThemeOptionTile(
                  context: ctx,
                  title: '시스템 설정 동기화',
                  subtitle: '기기 OS의 다크/라이트 설정에 자동 맞춤',
                  icon: Icons.brightness_auto_outlined,
                  isSelected: currentTheme == ThemeMode.system,
                  onTap: () {
                    ref
                        .read(analyticsServiceProvider)
                        .logEvent(
                          AnalyticsEvent.themeChange,
                          screenName: 'SettingsScreen',
                          properties: {'mode': 'system'},
                        );
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.system);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(appLocaleProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).cardTheme.color ??
                  AppColors.cardOf(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderOf(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t.settings.language,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimaryOf(context),
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildThemeOptionTile(
                  context: ctx,
                  title: t.settings.langKo,
                  subtitle: '한국어 (기본)',
                  icon: Icons.language_rounded,
                  isSelected: currentLocale == AppLocale.ko,
                  onTap: () {
                    ref.read(appLocaleProvider.notifier).setLocale(AppLocale.ko);
                    Navigator.pop(ctx);
                  },
                ),
                _buildThemeOptionTile(
                  context: ctx,
                  title: t.settings.langEn,
                  subtitle: 'English (US)',
                  icon: Icons.language_rounded,
                  isSelected: currentLocale == AppLocale.en,
                  onTap: () {
                    ref.read(appLocaleProvider.notifier).setLocale(AppLocale.en);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildThemeOptionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color:
              isSelected ? AppColors.primary : AppColors.textPrimaryOf(context),
        ),
        title: Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            color:
                isSelected
                    ? AppColors.primary
                    : AppColors.textPrimaryOf(context),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySm.copyWith(
            color: AppColors.textSecondaryOf(context),
          ),
        ),
        trailing:
            isSelected
                ? const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 22,
                )
                : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final currentLocale = ref.watch(appLocaleProvider);
    final appVersionAsync = ref.watch(appVersionProvider);
    final appVersion = appVersionAsync.value ?? AppConstants.versionFallback;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Section 1: 일반 설정
            Text(
              '일반 설정',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.brightness_medium_rounded,
                      color: AppColors.textPrimaryOf(context),
                    ),
                    title: Text(
                      t.settings.theme,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    subtitle: Text(
                      themeMode == ThemeMode.light
                          ? t.settings.themeLight
                          : themeMode == ThemeMode.dark
                          ? t.settings.themeDark
                          : t.settings.themeSystem,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.textDisabled,
                    ),
                    onTap: () => _showThemeModePicker(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.language_rounded,
                      color: AppColors.textPrimaryOf(context),
                    ),
                    title: Text(
                      t.settings.language,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    subtitle: Text(
                      currentLocale == AppLocale.ko
                          ? t.settings.langKo
                          : t.settings.langEn,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.textDisabled,
                    ),
                    onTap: () => _showLanguagePicker(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: 고객지원
            Text(
              '고객지원 및 문의',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.textPrimaryOf(context),
                    ),
                    title: Text(
                      '개발팀 문의하기',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    subtitle: Text(
                      AppConstants.contactEmail,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                    trailing: Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: AppColors.textSecondaryOf(context),
                    ),
                    onTap: () => _copyEmail(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.textPrimaryOf(context),
                    ),
                    title: Text(
                      '앱 버전',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    subtitle: Text(
                      appVersion,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: 계정 관리
            Text(
              '계정 관리',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.logout_rounded,
                      color: AppColors.textPrimaryOf(context),
                    ),
                    title: Text(
                      '로그아웃',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.textDisabled,
                    ),
                    onTap: () => _showLogoutDialog(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.person_remove_outlined,
                      color: AppColors.statusRed,
                    ),
                    title: Text(
                      '회원 탈퇴',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.statusRed,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.textDisabled,
                    ),
                    onTap: () => _showDeleteAccountDialog(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
