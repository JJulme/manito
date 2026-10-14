import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/widget/overlapping_avatars.dart';
import 'package:manito/features/game/presentation/screens/main_play_dashboard_screen.dart';
import 'package:manito/features/rooms/presentation/rooms_provider.dart';
import 'package:manito/features/setup/presentation/screens/mission_setup_screen.dart';
import 'package:manito/features/setup/presentation/setup_provider.dart';

/// 홈 화면 [진행중] 마니또 카드 (제목, 마감시간/카운트다운, 참여 친구 아바타 스택)
class OngoingRoomCard extends ConsumerStatefulWidget {
  final RoomModel room;

  const OngoingRoomCard({super.key, required this.room});

  @override
  ConsumerState<OngoingRoomCard> createState() => _OngoingRoomCardState();
}

class _OngoingRoomCardState extends ConsumerState<OngoingRoomCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatRemaining(Duration diff) {
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
    final room = widget.room;
    final deadline = room.gameEndTime ??
        (room.createdAt.add(const Duration(minutes: 30)));
    final diff = deadline.difference(DateTime.now());
    final isUrgent = diff.inMinutes <= 10 && diff > Duration.zero;
    final membersAsync = ref.watch(roomMembersProvider(room.roomId));

    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayStr = weekdays[deadline.weekday - 1];
    final hourStr = deadline.hour.toString().padLeft(2, '0');
    final minStr = deadline.minute.toString().padLeft(2, '0');
    final deadlineStr = '${deadline.month}월 ${deadline.day}일 ($weekdayStr) $hourStr:$minStr';

    final currentUserId = ref.watch(currentUserProvider)?.id;

    return InkWell(
      onTap: () async {
        final currentMembers = membersAsync.value ??
            await ref.read(roomMembersProvider(room.roomId).future);
        final me = currentMembers?.where((m) => m.userId == currentUserId).firstOrNull;

        if (context.mounted) {
          // 게임이 이미 시작(ONGOING)된 방인 경우
          if (room.status == RoomStatus.ongoing) {
            if (me != null && !me.isMissionSelected) {
              // 아직 미션이 선택 안 되었다면 백그라운드에서 랜덤 자동 배정
              unawaited(
                ref.read(missionSetupProvider.notifier).confirmSelection(me.roomMemberId, room.roomId, null),
              );
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MainPlayDashboardScreen(roomId: room.roomId),
              ),
            );
          } else {
            // 아직 SETUP 단계인 경우
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MissionSetupScreen(roomId: room.roomId),
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isUrgent ? AppColors.statusRed.withValues(alpha: 0.5) : AppColors.borderOf(context),
            width: isUrgent ? 1.2 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 상단: [진행중 뱃지 + 방 제목] & [실시간 카운트다운 타이머 뱃지]
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.statusGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '진행중',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.statusGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          room.title,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 실시간 카운트다운 배지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isUrgent
                          ? AppColors.statusRed.withValues(alpha: 0.12)
                          : AppColors.surfaceLowOf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUrgent ? AppColors.statusRed : AppColors.borderOf(context),
                        width: isUrgent ? 1.2 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.timer,
                          size: 14,
                          color: isUrgent ? AppColors.statusRed : AppColors.primaryDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatRemaining(diff),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: isUrgent ? AppColors.statusRed : AppColors.textPrimaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: AppColors.borderOf(context)),
              const SizedBox(height: 12),

              // 2. 하단: [참여 친구 아바타 스택] on Left & [마감 일시] on Right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  membersAsync.maybeWhen(
                    data: (members) {
                      final activeMembers = members.where((m) => m.joinStatus == '✔️').toList();
                      if (activeMembers.isEmpty) {
                        return const Text('참여 친구 로딩 중...', style: AppTypography.bodySm);
                      }
                      return OverlappingAvatars(
                        members: activeMembers,
                        avatarSize: 28,
                        countTextSuffix: '명 참여 중',
                      );
                    },
                    orElse: () => const Text('참여 친구 로딩 중...', style: AppTypography.bodySm),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.clock, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        deadlineStr,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
