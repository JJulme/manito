import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/widget/network_error_view.dart';
import 'package:manito/core/widget/user_avatar.dart';
import 'package:manito/core/analytics/analytics_event.dart';
import 'package:manito/core/analytics/analytics_service.dart';
import 'package:manito/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:manito/features/settings/presentation/screens/settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _copyToClipboard(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    AnalyticsService.instance.logEvent(
      AnalyticsEvent.myCodeCopy,
      screenName: 'ProfileScreen',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('고유 코드($code)가 클립보드에 복사되었습니다.'),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAutoReplyPreviewCard(
    BuildContext context, {
    required String title,
    required String? imageUrl,
    required String? text,
    required IconData icon,
    required String emptyFallbackText,
  }) {
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;
    final displayContent = (text != null && text.trim().isNotEmpty) ? text : emptyFallbackText;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppColors.cardShadowOf(context),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.titleSm.copyWith(color: AppColors.textPrimaryOf(context)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Attached Photo Preview (Full-Width, Rounded Corners & Uncropped)
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowOf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: imageUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          placeholder: (_, __) => Container(color: AppColors.surfaceOf(context)),
                          errorWidget: (_, __, ___) => Icon(LucideIcons.image_off, color: AppColors.textSecondaryOf(context)),
                        )
                      : Image.asset(imageUrl, width: double.infinity, fit: BoxFit.fitWidth),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 2. Text Content Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowOf(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Text(
              displayContent,
              style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimaryOf(context)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.pencil),
            tooltip: '프로필 수정',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(isFirstSetup: false),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.settings),
            tooltip: '환경설정',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => NetworkErrorView(
          title: '프로필을 불러오지 못했어요',
          onRetry: () => ref.invalidate(currentUserProfileProvider),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('사용자 정보를 찾을 수 없습니다.'));
          }

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Profile Header Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderOf(context)),
                    boxShadow: AppColors.cardShadowOf(context),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      UserAvatar(
                        imageUrl: user.profileImageUrl,
                        size: 96,
                        borderWidth: 2,
                        showShadow: true,
                        fallbackIconSize: 52,
                      ),
                      const SizedBox(height: 16),

                      // User Name
                      Text(
                        user.name,
                        style: AppTypography.headlineMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Status Message
                      if (user.statusMessage != null && user.statusMessage!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            user.statusMessage!,
                            style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondaryOf(context)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 14),

                      // 8-digit Unique Code Chip (Tap to copy)
                      InkWell(
                        onTap: () => _copyToClipboard(context, user.uniqueCode),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLowOf(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderOf(context)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.key, size: 16, color: AppColors.primaryDark),
                              const SizedBox(width: 6),
                              Text(
                                '고유코드: ${user.uniqueCode}',
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.textPrimaryOf(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(LucideIcons.copy, size: 14, color: AppColors.textSecondaryOf(context)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 2. Section: Auto-Reply Showcase
                Text(
                  '내 자동응답 프리셋',
                  style: AppTypography.titleMd.copyWith(color: AppColors.textPrimaryOf(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  '마감 시간까지 미참여 시 피드에 대신 노출될 게시물입니다.',
                  style: AppTypography.bodySm.copyWith(color: AppColors.textSecondaryOf(context)),
                ),
                const SizedBox(height: 12),

                // 3. Manito Auto-Reply Showcase Card
                _buildAutoReplyPreviewCard(
                  context,
                  title: '마니또 자동응답',
                  imageUrl: user.manitoAutoReplyImg,
                  text: user.manitoAutoReplyText,
                  icon: LucideIcons.lock,
                  emptyFallbackText: '설정된 마니또 자동응답 문구가 없습니다.',
                ),
                const SizedBox(height: 16),

                // 4. Guess Auto-Reply Showcase Card
                _buildAutoReplyPreviewCard(
                  context,
                  title: '추측 자동응답',
                  imageUrl: user.guessAutoReplyImg,
                  text: user.guessAutoReplyText,
                  icon: LucideIcons.brain,
                  emptyFallbackText: '설정된 추측 자동응답 문구가 없습니다.',
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}
