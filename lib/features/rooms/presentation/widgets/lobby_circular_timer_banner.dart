import 'dart:async';
import 'package:flutter/material.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/features/rooms/presentation/widgets/clockwise_timer_painter.dart';

/// 10분 대기실 실시간 원형 타이머 링 & 60초 긴급 카운트다운 위젯
class LobbyCircularTimerBanner extends StatefulWidget {
  final DateTime createdAt;
  final VoidCallback? onExpired;

  const LobbyCircularTimerBanner({
    super.key,
    required this.createdAt,
    this.onExpired,
  });

  @override
  State<LobbyCircularTimerBanner> createState() => _LobbyCircularTimerBannerState();
}

class _LobbyCircularTimerBannerState extends State<LobbyCircularTimerBanner> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
        final elapsedSec = DateTime.now().difference(widget.createdAt).inSeconds;
        if (elapsedSec >= 600) {
          widget.onExpired?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsedSec = DateTime.now().difference(widget.createdAt).inSeconds;
    final remainingSec = (600 - elapsedSec).clamp(0, 600);
    final progress = remainingSec / 600.0;
    final isUrgent = remainingSec <= 60;
    final isDark = AppColors.isDark(context);

    final themeColor = isUrgent
        ? AppColors.statusRed
        : (isDark ? AppColors.primary : AppColors.primaryDark);
    final bgColor = isUrgent
        ? AppColors.statusRed.withValues(alpha: 0.1)
        : (isDark ? AppColors.primary.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.15));
    final borderColor = isUrgent
        ? AppColors.statusRed.withValues(alpha: 0.5)
        : (isDark ? AppColors.primary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.4));
    final trackColor = isUrgent
        ? AppColors.statusRed.withValues(alpha: 0.2)
        : (isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.25));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: isUrgent ? 1.5 : 1.0),
      ),
      child: Row(
        children: [
          // 1. Text Information (Left-aligned)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isUrgent ? '⚠️ 대기실 폭파 임박!' : '⏱️ 대기실 유효시간',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isUrgent
                      ? '지금 게임을 시작하지 않으면 방이 자동으로 삭제됩니다.'
                      : '10분 내 미시작 시 방이 자동으로 폭파(삭제)됩니다.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isUrgent
                        ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                        : AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // 2. True Clockwise Countdown Progress Ring (Right-aligned)
          SizedBox(
            width: 48,
            height: 48,
            child: CustomPaint(
              painter: ClockwiseTimerPainter(
                progress: progress,
                trackColor: trackColor,
                progressColor: themeColor,
                strokeWidth: 4.0,
              ),
              child: Center(
                child: isUrgent
                    ? Text(
                        '$remainingSec',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.statusRed,
                          height: 1.0,
                        ),
                      )
                    : Text(
                        '${(remainingSec / 60).ceil()}분',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          height: 1.0,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
