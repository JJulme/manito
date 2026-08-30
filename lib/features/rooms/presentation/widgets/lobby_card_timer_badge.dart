import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:manito/features/rooms/presentation/rooms_provider.dart';
import 'package:manito/features/rooms/presentation/widgets/clockwise_timer_painter.dart';

/// 홈 화면 카드용 10분 대기실 실시간 원형 타이머 링
class LobbyCardTimerBadge extends ConsumerStatefulWidget {
  final DateTime createdAt;
  final String? roomId;
  final bool isHost;
  final VoidCallback? onExpired;

  const LobbyCardTimerBadge({
    super.key,
    required this.createdAt,
    this.roomId,
    this.isHost = false,
    this.onExpired,
  });

  @override
  ConsumerState<LobbyCardTimerBadge> createState() => _LobbyCardTimerBadgeState();
}

class _LobbyCardTimerBadgeState extends ConsumerState<LobbyCardTimerBadge> {
  late Timer _timer;
  bool _hasExpiredTriggered = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
        final elapsedSec = DateTime.now().difference(widget.createdAt).inSeconds;
        if (elapsedSec >= 600 && !_hasExpiredTriggered) {
          _hasExpiredTriggered = true;
          widget.onExpired?.call();
          if (widget.roomId != null && widget.isHost) {
            ref.read(roomsRepositoryProvider).deleteRoom(widget.roomId!).catchError((e) {
              AppLogger.e('Auto delete expired room error: $e', tag: 'ROOMS');
            });
          }
          ref.invalidate(ongoingRoomsProvider);
          ref.invalidate(receivedRoomInvitationsProvider);
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

    final themeColor = isUrgent ? AppColors.statusRed : AppColors.primaryDark;
    final trackColor = isUrgent
        ? AppColors.statusRed.withValues(alpha: 0.2)
        : AppColors.primary.withValues(alpha: 0.25);

    return SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(
        painter: ClockwiseTimerPainter(
          progress: progress,
          trackColor: trackColor,
          progressColor: themeColor,
          strokeWidth: 3.5,
        ),
        child: Center(
          child: isUrgent
              ? Text(
                  '$remainingSec',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.statusRed,
                    height: 1.0,
                  ),
                )
              : Text(
                  '${(remainingSec / 60).ceil()}분',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    height: 1.0,
                  ),
                ),
        ),
      ),
    );
  }
}
