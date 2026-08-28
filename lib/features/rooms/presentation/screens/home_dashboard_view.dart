import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:manito/core/widget/manito_logo.dart';
import 'package:manito/core/widget/manito_mascot.dart';
import 'package:manito/core/widget/user_avatar.dart';
import 'package:manito/features/friends/presentation/friends_provider.dart';
import 'package:manito/features/game/presentation/screens/main_play_dashboard_screen.dart';
import 'package:manito/features/rooms/presentation/rooms_provider.dart';
import 'package:manito/features/rooms/presentation/screens/group_lobby_screen.dart';
import 'package:manito/features/setup/presentation/setup_provider.dart';
import 'package:manito/features/setup/presentation/screens/mission_setup_screen.dart';

class HomeDashboardView extends ConsumerWidget {
  const HomeDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ongoingRoomsAsync = ref.watch(ongoingRoomsProvider);
    final validOngoingRooms = (ongoingRoomsAsync.value ?? []).where((room) {
      if (room.status == RoomStatus.waiting) {
        return DateTime.now().difference(room.createdAt).inSeconds < 600;
      }
      return true;
    }).toList();
    final hasOngoingRoom = validOngoingRooms.isNotEmpty;
    final invitationsAsync = ref.watch(receivedRoomInvitationsProvider);
    final friendsAsync = ref.watch(acceptedFriendsProvider);
    final receivedFriendRequestsAsync = ref.watch(receivedFriendRequestsProvider);
    final hasFriendRequests = receivedFriendRequestsAsync.value?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const ManitoLogo(fontSize: 26),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ongoingRoomsProvider);
          ref.invalidate(receivedRoomInvitationsProvider);
          ref.invalidate(acceptedFriendsProvider);
          ref.invalidate(receivedFriendRequestsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Create Room CTA (Only visible when NOT in any ongoing room)
              if (!hasOngoingRoom) ...[
                ElevatedButton.icon(
                  onPressed: () => context.push('/invite_friends'),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                  label: const Text('새 마니또 방 개설하기'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // 2. Received Invitations Section (받은 초대)
              invitationsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (invites) {
                  if (invites.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Text('받은 초대장', style: AppTypography.titleMd),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.statusRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: invites.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final invite = invites[idx];
                          final hostProfile = invite.userProfile;
                          final roomTitle = invite.room?.title ?? '마니또 비밀 초대';

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  UserAvatar(
                                    imageUrl: hostProfile?.profileImageUrl,
                                    size: 44,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          roomTitle,
                                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '방장: ${hostProfile?.name ?? "요원"}',
                                          style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check_rounded, color: AppColors.statusGreen, size: 28),
                                    tooltip: '수락',
                                    onPressed: () async {
                                      if (hasOngoingRoom) {
                                        showDialog(
                                          context: context,
                                          builder: (dialogCtx) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            title: Row(
                                              children: const [
                                                Icon(Icons.info_outline_rounded, color: AppColors.primaryDark),
                                                SizedBox(width: 8),
                                                Text('초대 수락 불가', style: AppTypography.titleMedium),
                                              ],
                                            ),
                                            content: const Text(
                                              '현재 이미 진행 중이거나 대기 중인 마니또 방이 있습니다.\n마니또는 한 번에 1개의 방에만 참여할 수 있으므로, 기존 방이 종료된 후 수락해 주세요.',
                                              style: AppTypography.bodyMedium,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(dialogCtx),
                                                child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        );
                                        return;
                                      }

                                      try {
                                        await ref.read(roomsRepositoryProvider).respondToInvitation(invite.roomMemberId, '✔️');
                                        ref.invalidate(receivedRoomInvitationsProvider);
                                        ref.invalidate(ongoingRoomsProvider);
                                        if (context.mounted) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => GroupLobbyScreen(roomId: invite.roomId),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('수락 실패: $e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, color: AppColors.statusRed, size: 28),
                                    tooltip: '거절',
                                    onPressed: () async {
                                      await ref.read(roomsRepositoryProvider).respondToInvitation(invite.roomMemberId, 'X');
                                      ref.invalidate(receivedRoomInvitationsProvider);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('초대를 거절했습니다.')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                    ],
                  );
                },
              ),

              // 3. Ongoing Games Section (진행 중인 마니또)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('진행 중인 마니또', style: AppTypography.titleMd),
                ],
              ),
              const SizedBox(height: 12),

              ongoingRoomsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (err, _) => Center(child: Text('방 목록 조회 실패: $err')),
                data: (rooms) {
                  final validRooms = rooms.where((room) {
                    if (room.status == RoomStatus.waiting) {
                      return DateTime.now().difference(room.createdAt).inSeconds < 600;
                    }
                    return true;
                  }).toList();

                  if (validRooms.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                      alignment: Alignment.center,
                      child: Column(
                        children: const [
                          ManitoMascot.sunglass(width: 120, height: 120),
                          SizedBox(height: 16),
                          Text('진행 중인 마니또가 없습니다.', style: AppTypography.titleMedium),
                          SizedBox(height: 6),
                          Text('새 방을 개설하고 친구들을 초대해 보세요!',
                              textAlign: TextAlign.center, style: AppTypography.bodySm),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: validRooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final room = validRooms[idx];
                      if (room.status == RoomStatus.ongoing || room.status == RoomStatus.preparing) {
                        return OngoingRoomCard(room: room);
                      }
                      return WaitingRoomCard(room: room);
                    },
                  );
                },
              ),
              const SizedBox(height: 28),

              // 4. Friends List Section (친구 목록)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('내 친구', style: AppTypography.titleMd),
                      const SizedBox(width: 8),
                      friendsAsync.maybeWhen(
                        data: (friends) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLowOf(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderOf(context)),
                          ),
                          child: Text(
                            '${friends.length}명',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.textPrimaryOf(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.push('/add_friend'),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.person_add_alt_1_outlined, size: 16, color: AppColors.primaryDark),
                          const SizedBox(width: 4),
                          Text(
                            '친구 추가',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (hasFriendRequests) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.statusRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              friendsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (err, _) => Center(child: Text('친구 목록 로드 실패: $err')),
                data: (friends) {
                  if (friends.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLowOf(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderOf(context)),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.group_outlined, size: 40, color: AppColors.textDisabled),
                          const SizedBox(height: 10),
                          const Text('아직 등록된 친구가 없습니다.', style: AppTypography.bodyMd),
                          const SizedBox(height: 4),
                          const Text('8자리 고유 코드로 친구를 추가해보세요!', style: AppTypography.bodySm),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/add_friend'),
                            icon: const Icon(Icons.search_rounded, size: 16),
                            label: const Text('친구 검색 및 추가'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: friends.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final friend = friends[idx];
                      final profile = friend.friendProfile;

                      return Card(
                        child: InkWell(
                          onTap: () => context.push('/friend_detail', extra: friend),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                UserAvatar(
                                  imageUrl: profile?.profileImageUrl,
                                  size: 44,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(profile?.name ?? '알 수 없는 요원', style: AppTypography.titleSmall),
                                      const SizedBox(height: 2),
                                      Text(
                                        profile?.statusMessage?.isNotEmpty == true
                                            ? profile!.statusMessage!
                                            : '코드: ${profile?.uniqueCode ?? "-"}',
                                        style: AppTypography.bodySm,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

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
            if (me != null && !me.isMissionSelected) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MissionSetupScreen(roomId: room.roomId),
                ),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MainPlayDashboardScreen(roomId: room.roomId),
                ),
              );
            }
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
                          Icons.timer_outlined,
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
                      return _buildOverlappingAvatars(activeMembers);
                    },
                    orElse: () => const Text('참여 친구 로딩 중...', style: AppTypography.bodySm),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondary),
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

  Widget _buildOverlappingAvatars(List<RoomMemberModel> members) {
    const maxAvatars = 4;
    final displayMembers = members.take(maxAvatars).toList();
    final extraCount = members.length - maxAvatars;
    final cardBg = Theme.of(context).cardTheme.color ?? AppColors.cardOf(context);

    return Row(
      children: [
        SizedBox(
          width: (displayMembers.length * 18.0) + (extraCount > 0 ? 28.0 : 10.0),
          height: 28,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < displayMembers.length; i++)
                Positioned(
                  left: i * 18.0,
                  child: UserAvatar(
                    imageUrl: displayMembers[i].userProfile?.profileImageUrl,
                    size: 28,
                    borderWidth: 2,
                    borderColor: cardBg,
                    showShadow: true,
                  ),
                ),
              if (extraCount > 0)
                Positioned(
                  left: displayMembers.length * 18.0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceLowOf(context),
                      border: Border.all(color: cardBg, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+$extraCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${members.length}명 참여 중',
          style: AppTypography.bodySm.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryOf(context),
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}

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
