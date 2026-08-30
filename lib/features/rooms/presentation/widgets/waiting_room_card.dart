import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/widget/user_avatar.dart';
import 'package:manito/features/rooms/presentation/rooms_provider.dart';
import 'package:manito/features/rooms/presentation/screens/group_lobby_screen.dart';
import 'package:manito/features/rooms/presentation/widgets/lobby_card_timer_badge.dart';

/// 홈 화면 [대기중] 마니또 카드 (방장 아바타, 생성 시각, 10분 대기실 타이머 링)
class WaitingRoomCard extends ConsumerWidget {
  final RoomModel room;

  const WaitingRoomCard({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostProfile = room.hostProfile;
    final hostName = hostProfile?.name ?? '요원';
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final isHost = room.hostId == currentUserId;
    final createdDateStr =
        '${room.createdAt.month}월 ${room.createdAt.day}일 ${room.createdAt.hour.toString().padLeft(2, '0')}:${room.createdAt.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroupLobbyScreen(roomId: room.roomId),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.borderOf(context)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section: [대기중 뱃지 + Title] on Left, [Timer Ring] on Right
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '대기중',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
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
                  LobbyCardTimerBadge(
                    createdAt: room.createdAt,
                    roomId: room.roomId,
                    isHost: isHost,
                    onExpired: () {
                      ref.invalidate(ongoingRoomsProvider);
                      ref.invalidate(receivedRoomInvitationsProvider);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: AppColors.borderOf(context)),
              const SizedBox(height: 10),

              // Bottom Section: Host avatar + name + [방장] + timestamp
              Row(
                children: [
                  UserAvatar(
                    imageUrl: hostProfile?.profileImageUrl,
                    size: 22,
                    borderWidth: 0.8,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hostName,
                    style: AppTypography.bodySm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '방장',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('·', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  Text(
                    '$createdDateStr 생성',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
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
