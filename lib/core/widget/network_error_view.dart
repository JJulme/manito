import 'package:flutter/material.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/widget/manito_mascot.dart';

/// 재사용 가능한 네트워크/데이터 로드 에러 뷰 위젯
class NetworkErrorView extends StatelessWidget {
  final VoidCallback? onRetry;
  final String title;
  final String message;
  final bool isCompact;

  const NetworkErrorView({
    super.key,
    this.onRetry,
    this.title = '네트워크 연결이 원활하지 않아요',
    this.message = '인터넷 연결 상태를 확인하신 후\n다시 시도해 주세요.',
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 32,
              color: AppColors.textSecondaryOf(context),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimaryOf(context),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: AppTypography.labelMd,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 마스코트 + Wi-Fi 단절 오버레이
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: ManitoMascot.thinking(width: 84, height: 84),
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.statusRed,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 타이틀
            Text(
              title,
              style: AppTypography.headlineMd.copyWith(
                color: AppColors.textPrimaryOf(context),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // 설명
            Text(
              message,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.textSecondaryOf(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // 다시 시도 버튼
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 독립 Scaffold 기반 풀스크린 네트워크 에러 화면
class NetworkErrorScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  final String title;
  final String message;
  final bool showBackButton;

  const NetworkErrorScreen({
    super.key,
    this.onRetry,
    this.title = '네트워크 연결이 원활하지 않아요',
    this.message = '인터넷 연결 상태를 확인하신 후\n다시 시도해 주세요.',
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
      ),
      body: SafeArea(
        child: NetworkErrorView(
          onRetry: onRetry,
          title: title,
          message: message,
        ),
      ),
    );
  }
}
