import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/core/analytics/analytics_event.dart';
import 'package:manito/core/analytics/analytics_service.dart';
import 'package:manito/core/notifications/app_notification_service.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:manito/main.dart';
import 'package:manito/features/rooms/presentation/rooms_provider.dart';

/// 대기실 나가기 / 방 삭제 확인 바텀시트
class LobbyLeaveBottomSheet extends ConsumerStatefulWidget {
  final String roomId;
  final bool isHost;
  final VoidCallback onLeaveStart;

  const LobbyLeaveBottomSheet({
    super.key,
    required this.roomId,
    required this.isHost,
    required this.onLeaveStart,
  });

  static Future<void> show(
    BuildContext context, {
    required String roomId,
    required bool isHost,
    required VoidCallback onLeaveStart,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LobbyLeaveBottomSheet(
        roomId: roomId,
        isHost: isHost,
        onLeaveStart: onLeaveStart,
      ),
    );
  }

  @override
  ConsumerState<LobbyLeaveBottomSheet> createState() => _LobbyLeaveBottomSheetState();
}

class _LobbyLeaveBottomSheetState extends ConsumerState<LobbyLeaveBottomSheet> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isHost = widget.isHost;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.statusRed.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: AppColors.statusRed,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isHost ? '마니또 방 삭제 및 나가기' : '대기실 나가기',
            style: AppTypography.headlineMd,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            isHost
                ? '⚠️ 방장이 대기실을 나가면 개설된 방이 완전히 삭제되며, 모든 참가자가 퇴장 처리됩니다.\n정말 방을 삭제하고 나가시겠습니까?'
                : '대기실에서 퇴장하시겠습니까?\n언제든 다시 초대를 받아 참여할 수 있습니다.',
            style: AppTypography.bodyMd.copyWith(
              color: isHost ? AppColors.statusRed : AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.borderOf(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: AppColors.textPrimaryOf(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            setState(() => _isProcessing = true);
                            widget.onLeaveStart();

                            try {
                              final repo = ref.read(roomsRepositoryProvider);
                              ref.read(analyticsServiceProvider).logEvent(
                                isHost ? AnalyticsEvent.roomDelete : AnalyticsEvent.roomLeave,
                                screenName: 'GroupLobbyScreen',
                                properties: {'room_id': widget.roomId},
                              );
                              if (isHost) {
                                await repo.deleteRoom(widget.roomId);
                              } else {
                                await repo.leaveRoom(widget.roomId);
                              }
                              ref.read(appNotificationServiceProvider).cancelGameDeadlineNotifications(widget.roomId);
                              ref.invalidate(ongoingRoomsProvider);
                              ref.invalidate(receivedRoomInvitationsProvider);

                              if (context.mounted) {
                                Navigator.pop(context);
                                Navigator.of(context).popUntil((route) => route.isFirst);
                                context.go('/bottom_nav2');
                                scaffoldMessengerKey.currentState?.showSnackBar(
                                  SnackBar(
                                    content: Text(isHost ? '방이 삭제되었습니다.' : '대기실에서 퇴장했습니다.'),
                                    backgroundColor: AppColors.textPrimary,
                                  ),
                                );
                              }
                            } catch (e, s) {
                              if (mounted) {
                                setState(() => _isProcessing = false);
                                AppLogger.e('나가기 실패', error: e, stackTrace: s);
                                scaffoldMessengerKey.currentState?.showSnackBar(
                                  const SnackBar(content: Text('나가기에 실패했습니다. 다시 시도해 주세요.')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isHost ? '방 삭제' : '나가기',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
