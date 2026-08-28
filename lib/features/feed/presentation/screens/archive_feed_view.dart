import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/widget/manito_mascot.dart';
import 'package:manito/core/widget/user_avatar.dart';
import 'package:manito/features/feed/presentation/feed_provider.dart';
import 'package:manito/features/feed/presentation/screens/result_feed_screen.dart';
import 'package:manito/features/rooms/presentation/rooms_provider.dart';

class ArchiveFeedView extends ConsumerWidget {
  const ArchiveFeedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedRoomsAsync = ref.watch(completedRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('기록'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(completedRoomsProvider),
        child: completedRoomsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Text('기록 목록을 불러오지 못했습니다: $err'),
          ),
          data: (rooms) {
            if (rooms.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const ManitoMascot.selfie(width: 120, height: 120),
                      const SizedBox(height: 16),
                      Text(
                        '완료된 마니또 기록이 없습니다.',
                        style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimaryOf(context)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '마니또가 종료되면 이곳에 추억과 사진이 안전하게 기록됩니다.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySm.copyWith(color: AppColors.textSecondaryOf(context)),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: rooms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final room = rooms[idx];
                return RecordHistoryCard(room: room);
              },
            );
          },
        ),
      ),
    );
  }
}

/// A형 가로형 리스트 카드 (왼쪽: 80x80 썸네일, 오른쪽: 제목 + 시작~종료 기간 + 참여 친구 아바타 스택)
class RecordHistoryCard extends ConsumerWidget {
  final RoomModel room;

  const RecordHistoryCard({super.key, required this.room});

  String _formatDateRange(DateTime? start, DateTime? end, DateTime fallbackCreated) {
    var s = start ?? fallbackCreated;
    final e = end;

    // 방어적 보정: 시작 시간이 종료 시간보다 미래인 경우 (과거 로컬/UTC 변환 오차 등) created_at 또는 end 기준으로 보정
    if (e != null && s.isAfter(e)) {
      s = fallbackCreated.isBefore(e) ? fallbackCreated : e.subtract(const Duration(minutes: 30));
    }

    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final sWeekday = weekdays[s.weekday - 1];
    final sMonth = s.month.toString().padLeft(2, '0');
    final sDay = s.day.toString().padLeft(2, '0');
    final sHour = s.hour.toString().padLeft(2, '0');
    final sMin = s.minute.toString().padLeft(2, '0');

    if (e == null) {
      return '$sMonth.$sDay ($sWeekday) $sHour:$sMin';
    }

    final eMonth = e.month.toString().padLeft(2, '0');
    final eDay = e.day.toString().padLeft(2, '0');
    final eHour = e.hour.toString().padLeft(2, '0');
    final eMin = e.minute.toString().padLeft(2, '0');
    final eWeekday = weekdays[e.weekday - 1];

    if (s.year == e.year && s.month == e.month && s.day == e.day) {
      return '$sMonth.$sDay ($sWeekday) $sHour:$sMin ~ $eHour:$eMin';
    } else {
      return '$sMonth.$sDay ($sWeekday) ~ $eMonth.$eDay ($eWeekday)';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailAsync = ref.watch(roomThumbnailProvider(room.roomId));
    final membersAsync = ref.watch(roomMembersProvider(room.roomId));
    final unreadCount = ref.watch(roomUnreadCommentCountProvider(room.roomId));
    final dateRangeStr = _formatDateRange(room.gameStartTime, room.gameEndTime, room.createdAt);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultFeedScreen(roomId: room.roomId),
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
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. 왼쪽: 80x80 대표 썸네일 사진
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: thumbnailAsync.maybeWhen(
                    data: (url) {
                      if (url != null && url.isNotEmpty) {
                        return url.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: url,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _buildPlaceholder(),
                                errorWidget: (_, __, ___) => _buildPlaceholder(),
                              )
                            : Image.asset(
                                url,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildPlaceholder(),
                              );
                      }
                      return _buildPlaceholder();
                    },
                    orElse: () => _buildPlaceholder(),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // 2. 오른쪽: 제목 + 시작~종료 기간 + 참여 친구 미니 프로필 스택
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 방 제목 + 미확인 댓글 뱃지
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.title,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.textPrimaryOf(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // 시작 ~ 종료 일시 (한 줄로 깔끔하고 직관적인 포맷)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12.5,
                          color: AppColors.textSecondaryOf(context),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            dateRangeStr,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.textSecondaryOf(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 참여 친구 미니 프로필 겹쳐진 모습
                    membersAsync.maybeWhen(
                      data: (members) {
                        final activeMembers = members.where((m) => m.joinStatus == '✔️').toList();
                        if (activeMembers.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return _buildOverlappingAvatars(context, activeMembers);
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(
          Icons.photo_library_outlined,
          color: AppColors.textDisabled,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildOverlappingAvatars(BuildContext context, List<RoomMemberModel> members) {
    const maxDisplay = 4;
    final displayMembers = members.take(maxDisplay).toList();
    final extraCount = members.length - displayMembers.length;
    final cardBg = Theme.of(context).cardTheme.color ?? AppColors.cardOf(context);

    return Row(
      children: [
        SizedBox(
          width: (displayMembers.length * 16.0) + (extraCount > 0 ? 24.0 : 8.0),
          height: 24,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < displayMembers.length; i++)
                Positioned(
                  left: i * 16.0,
                  child: UserAvatar(
                    imageUrl: displayMembers[i].userProfile?.profileImageUrl,
                    size: 24,
                    borderWidth: 1.5,
                    borderColor: cardBg,
                    showShadow: true,
                    fallbackIconSize: 14,
                  ),
                ),
              if (extraCount > 0)
                Positioned(
                  left: displayMembers.length * 16.0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceLowOf(context),
                      border: Border.all(color: cardBg, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+$extraCount',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${members.length}명',
          style: AppTypography.bodySm.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryOf(context),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
