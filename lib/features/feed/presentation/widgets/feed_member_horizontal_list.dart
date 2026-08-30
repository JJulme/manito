import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/widget/user_avatar.dart';
import 'package:manito/features/feed/presentation/feed_provider.dart';

/// 상단 가로 스크롤 친구 프로필 바 (깔끔한 원형 아바타 + 이름 + 미확인 댓글 뱃지)
class FeedMemberHorizontalList extends ConsumerWidget {
  final List<RoomMemberModel> members;
  final String selectedId;
  final List<RecordModel> records;
  final ValueChanged<String> onMemberSelected;

  const FeedMemberHorizontalList({
    super.key,
    required this.members,
    required this.selectedId,
    required this.records,
    required this.onMemberSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadSummary = ref.watch(unreadCommentSummaryProvider).value;

    return Container(
      height: 90,
      color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, idx) {
          final member = members[idx];
          final isSelected = member.userId == selectedId;
          final profile = member.userProfile;
          final name = profile?.name ?? '요원';
          final imgUrl = profile?.profileImageUrl;

          // A의 마니또였던 B
          final manitoB = members.firstWhere(
            (other) => other.targetUserId == member.userId,
            orElse: () => member,
          );

          // 이 멤버와 관련된 레코드들
          final missionRecord = records.cast<RecordModel?>().firstWhere(
            (r) => r?.userId == manitoB.userId && r?.recordType == RecordType.missionPerform,
            orElse: () => null,
          );
          final guessRecord = records.cast<RecordModel?>().firstWhere(
            (r) => r?.userId == member.userId && r?.recordType == RecordType.suspectGuess,
            orElse: () => null,
          );

          final missionUnread = missionRecord != null ? (unreadSummary?.recordCounts[missionRecord.recordId] ?? 0) : 0;
          final guessUnread = guessRecord != null ? (unreadSummary?.recordCounts[guessRecord.recordId] ?? 0) : 0;
          final hasMemberUnread = (missionUnread + guessUnread) > 0;

          return InkWell(
            onTap: () => onMemberSelected(member.userId),
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: 56,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      UserAvatar(
                        imageUrl: imgUrl,
                        size: 48,
                        borderWidth: isSelected ? 2.5 : 1.0,
                        borderColor: isSelected ? AppColors.primary : AppColors.borderOf(context),
                      ),
                      if (hasMemberUnread)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context), width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimaryOf(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
