import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:manito/features/settings/presentation/screens/settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _copyToClipboard(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    // 안드로이드는 시스템 자체 클립보드 오버레이가 뜨므로 iOS에서만 인앱 스낵바 안내 노출
    if (Theme.of(context).platform == TargetPlatform.iOS) {
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
  }

  Widget _buildAutoReplyPreviewCard({
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
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
              Text(title, style: AppTypography.titleSm),
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
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: imageUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          placeholder: (_, __) => Container(color: AppColors.surface),
                          errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
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
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              displayContent,
              style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
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
            icon: const Icon(Icons.edit_outlined),
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
            icon: const Icon(Icons.settings_outlined),
            tooltip: '환경설정',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('프로필 로드 실패: $err')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('사용자 정보를 찾을 수 없습니다.'));
          }

          final hasProfileImage = user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty;

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
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceLow,
                          border: Border.all(color: AppColors.border, width: 2),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: ClipOval(
                          child: hasProfileImage
                              ? (user.profileImageUrl!.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: user.profileImageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(color: AppColors.surface),
                                      errorWidget: (_, __, ___) => const Icon(Icons.person_rounded, size: 52, color: AppColors.textDisabled),
                                    )
                                  : Image.asset(user.profileImageUrl!, fit: BoxFit.cover))
                              : const Icon(Icons.person_rounded, size: 52, color: AppColors.textDisabled),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // User Name
                      Text(
                        user.name,
                        style: AppTypography.headlineMd.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),

                      // Status Message
                      if (user.statusMessage != null && user.statusMessage!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            user.statusMessage!,
                            style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
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
                            color: AppColors.surfaceLow,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.vpn_key_outlined, size: 16, color: AppColors.primaryDark),
                              const SizedBox(width: 6),
                              Text(
                                '고유코드: ${user.uniqueCode}',
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.copy_rounded, size: 14, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 2. Section: Auto-Reply Showcase
                const Text('내 자동응답 프리셋', style: AppTypography.titleMd),
                const SizedBox(height: 4),
                const Text(
                  '마감 시간까지 미참여 시 피드에 대신 노출될 게시물입니다.',
                  style: AppTypography.bodySm,
                ),
                const SizedBox(height: 12),

                // 3. Manito Auto-Reply Showcase Card
                _buildAutoReplyPreviewCard(
                  title: '마니또 자동응답',
                  imageUrl: user.manitoAutoReplyImg,
                  text: user.manitoAutoReplyText,
                  icon: Icons.lock_clock_outlined,
                  emptyFallbackText: '설정된 마니또 자동응답 문구가 없습니다.',
                ),
                const SizedBox(height: 16),

                // 4. Guess Auto-Reply Showcase Card
                _buildAutoReplyPreviewCard(
                  title: '추측 자동응답',
                  imageUrl: user.guessAutoReplyImg,
                  text: user.guessAutoReplyText,
                  icon: Icons.psychology_outlined,
                  emptyFallbackText: '설정된 추측 자동응답 문구가 없습니다.',
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
