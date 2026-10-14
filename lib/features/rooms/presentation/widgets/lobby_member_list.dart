import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/widget/user_avatar.dart';

/// 대기실 참여 인원 목록 및 상태 뱃지 위젯
class LobbyMemberList extends StatelessWidget {
  final List<RoomMemberModel> members;
  final RoomModel room;
  final String? currentUserId;
  final bool isHost;
  final VoidCallback onInviteTap;

  const LobbyMemberList({
    super.key,
    required this.members,
    required this.room,
    required this.currentUserId,
    required this.isHost,
    required this.onInviteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Operatives Header & Invite Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '참여 인원 (${members.length}명)',
              style: AppTypography.titleMd.copyWith(color: AppColors.textPrimaryOf(context)),
            ),
            if (isHost && room.status == RoomStatus.waiting)
              InkWell(
                onTap: onInviteTap,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(LucideIcons.user_plus, size: 14, color: AppColors.textSecondaryOf(context)),
                      const SizedBox(width: 4),
                      Text(
                        '친구 추가',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryOf(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // 2. Operatives List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: members.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, idx) {
            final member = members[idx];
            final isMe = member.userId == currentUserId;
            final isMemberHost = member.userId == room.hostId;
            final profile = member.userProfile;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isMe
                      ? (AppColors.isDark(context) ? AppColors.primary : AppColors.primaryDark)
                      : AppColors.borderOf(context),
                  width: isMe ? 1.5 : 1.0,
                ),
                boxShadow: AppColors.cardShadowOf(context),
              ),
              child: Row(
                children: [
                  UserAvatar(
                    imageUrl: profile?.profileImageUrl,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              profile?.name ?? (isMe ? '나' : '요원'),
                              style: AppTypography.titleSm.copyWith(
                                color: AppColors.textPrimaryOf(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (isMemberHost) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.isDark(context)
                                      ? AppColors.darkPrimaryLight
                                      : AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '방장',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDarkOf(context),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile?.statusMessage?.isNotEmpty == true
                              ? profile!.statusMessage!
                              : '코드: ${profile?.uniqueCode ?? "-"}',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.textSecondaryOf(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: member.joinStatus == '✔️'
                          ? AppColors.statusGreen.withValues(alpha: 0.15)
                          : member.joinStatus == 'X'
                              ? AppColors.statusRed.withValues(alpha: 0.15)
                              : AppColors.surfaceLowOf(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      member.joinStatus == '✔️'
                          ? '수락됨'
                          : member.joinStatus == 'X'
                              ? '거절됨'
                              : '대기중',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: member.joinStatus == '✔️'
                            ? AppColors.statusGreen
                            : member.joinStatus == 'X'
                                ? AppColors.statusRed
                                : AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // 3. Waiting Notice for Non-host Members
        if (!isHost) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowOf(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.hourglass,
                  color: AppColors.isDark(context) ? AppColors.primary : AppColors.primaryDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '방장이 참가자들을 모아 게임을 시작할 때까지 잠시만 대기해주세요.',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
