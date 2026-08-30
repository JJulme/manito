import 'package:flutter/material.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';

/// 대기실 유효시간 만료(10분) 또는 방장에 의한 삭제 알림 바텀시트
class LobbyRoomExpiredBottomSheet extends StatelessWidget {
  final bool isTimeExpired;

  const LobbyRoomExpiredBottomSheet({
    super.key,
    this.isTimeExpired = false,
  });

  static Future<void> show(BuildContext context, {bool isTimeExpired = false}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => LobbyRoomExpiredBottomSheet(isTimeExpired: isTimeExpired),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.statusRed.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTimeExpired ? Icons.timer_off_rounded : Icons.delete_outline_rounded,
              color: AppColors.statusRed,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isTimeExpired ? '대기실이 자동 삭제되었습니다' : '대기실이 삭제되었습니다',
            style: AppTypography.headlineMd,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            isTimeExpired
                ? '대기실 개설 후 10분 동안 게임이 시작되지 않아\n대기실이 자동으로 폭파(삭제)되었습니다.\n\n새로운 방을 개설하거나 친구들을 다시 초대해보세요!'
                : '방장에 의해 대기실이 삭제(폭파)되었습니다.\n\n새로운 방을 개설하거나 다른 초대를 확인해보세요!',
            style: AppTypography.bodyMd,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ),
        ],
      ),
    );
  }
}
