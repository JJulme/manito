import 'package:flutter/material.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/widget/user_avatar.dart';
import 'package:manito/features/feed/presentation/widgets/feed_record_content_blocks.dart';

/// [마니또 추측] 섹션: "A님이 추측한 마니또" -> 선택된 사용자 프로필(사진, 이름, 상태메시지) -> A가 작성한 내용
class FeedSuspectGuessSection extends StatelessWidget {
  final RoomMemberModel selectedMember;
  final RoomMemberModel manitoMember;
  final RecordModel? record;

  const FeedSuspectGuessSection({
    super.key,
    required this.selectedMember,
    required this.manitoMember,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final aName = selectedMember.userProfile?.name ?? '요원';
    final suspectUser = record?.suspectUser;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.borderOf(context)),
      ),
      color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. "A님이 추측한 마니또" 타이틀
            Text(
              '$aName님이 추측한 마니또',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 14),

            // 2. 선택한 사용자 프로필 (사진, 이름, 상태메시지)
            if (suspectUser != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowOf(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      imageUrl: suspectUser.profileImageUrl,
                      size: 44,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suspectUser.name,
                            style: AppTypography.bodyMd.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                          if (suspectUser.statusMessage != null && suspectUser.statusMessage!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              suspectUser.statusMessage!,
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.textSecondaryOf(context),
                                fontSize: 12.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 3. A가 작성한 단서 및 추측 내용 (사진 & 텍스트)
            if (record != null) ...[
              FeedRecordContentBlocks(blocks: record!.content),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                child: Text(
                  '$aName님이 등록한 기록이 없습니다.',
                  style: AppTypography.bodySm.copyWith(color: AppColors.textDisabledOf(context)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
