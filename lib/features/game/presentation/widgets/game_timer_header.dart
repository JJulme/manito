import 'package:flutter/material.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/util/game_time_util.dart';

/// 게임 플레이 화면 상단 앱바의 마감 시간 툴팁 및 남은 시간 뱃지
class GameTimerHeaderBadge extends StatelessWidget {
  final DateTime deadline;
  final Duration remainingDuration;

  const GameTimerHeaderBadge({
    super.key,
    required this.deadline,
    required this.remainingDuration,
  });

  String _formatRemainingDuration(Duration diff) {
    if (diff.inSeconds <= 0) return '00:00:00 (마감)';
    final days = diff.inDays;
    final hours = (diff.inHours % 24).toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

    if (days > 0) {
      return '$days일 $hours:$minutes:$seconds';
    }
    return '${diff.inHours.toString().padLeft(2, '0')}:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = remainingDuration.inMinutes <= 10 && remainingDuration > Duration.zero;

    return Tooltip(
      message: '마감 시간: ${GameTimeUtil.formatKoreanDateTime(deadline)}',
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.isDark(context) ? AppColors.darkCard : const Color(0xFF222222).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isUrgent
              ? AppColors.statusRed.withValues(alpha: 0.12)
              : AppColors.surfaceLowOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUrgent ? AppColors.statusRed : AppColors.borderOf(context),
            width: isUrgent ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 16,
              color: isUrgent
                  ? AppColors.statusRed
                  : (AppColors.isDark(context) ? AppColors.primary : AppColors.primaryDark),
            ),
            const SizedBox(width: 6),
            Text(
              _formatRemainingDuration(remainingDuration),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isUrgent ? AppColors.statusRed : AppColors.textPrimaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
