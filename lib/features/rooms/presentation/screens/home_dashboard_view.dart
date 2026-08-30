import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:manito/core/widget/manito_logo.dart';
import 'package:manito/core/widget/manito_mascot.dart';
import 'package:manito/core/widget/network_error_view.dart';
import 'package:manito/core/widget/user_avatar.dart';
import 'package:manito/features/friends/presentation/friends_provider.dart';
import 'package:manito/features/rooms/presentation/rooms_provider.dart';
import 'package:manito/features/rooms/presentation/screens/group_lobby_screen.dart';
import 'package:manito/features/rooms/presentation/widgets/ongoing_room_card.dart';
import 'package:manito/features/rooms/presentation/widgets/waiting_room_card.dart';

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
                                      } catch (e, s) {
                                        if (context.mounted) {
                                          AppLogger.e('수락 실패', error: e, stackTrace: s);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('수락에 실패했습니다. 다시 시도해 주세요.')),
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
                error: (err, _) => NetworkErrorView(
                  isCompact: true,
                  title: '방 목록을 불러오지 못했어요',
                  onRetry: () => ref.invalidate(ongoingRoomsProvider),
                ),
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
                          Icon(
                            Icons.person_add_rounded,
                            size: 15,
                            color: AppColors.textSecondaryOf(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '친구 추가',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.textSecondaryOf(context),
                              fontWeight: FontWeight.w600,
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
                error: (err, _) => NetworkErrorView(
                  isCompact: true,
                  title: '친구 목록을 불러오지 못했어요',
                  onRetry: () => ref.invalidate(acceptedFriendsProvider),
                ),
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
