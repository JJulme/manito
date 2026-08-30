import 'package:flutter/material.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/widget/user_avatar.dart';
import 'package:manito/features/feed/presentation/widgets/feed_record_content_blocks.dart';

/// [마니또 미션 수행] 섹션: B 프로필 -> B가 선택한 미션 내용 -> B가 작성한 내용
class FeedMissionPerformSection extends StatelessWidget {
  final RoomMemberModel selectedMember;
  final RoomMemberModel manitoMember;
  final RecordModel? record;
  final String lang;

  const FeedMissionPerformSection({
    super.key,
    required this.selectedMember,
    required this.manitoMember,
    required this.record,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final aName = selectedMember.userProfile?.name ?? '요원';
    final bProfile = manitoMember.userProfile;
    final bName = bProfile?.name ?? '마니또';
    final bProfileImg = bProfile?.profileImageUrl;
    final assignedMission = manitoMember.assignedMission?.getContent(lang);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.borderOf(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. "A님의 마니또" 타이틀
            Text(
              '$aName님의 마니또',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 14),

            // 2. B의 프로필 (사진, 이름, 상태메시지)
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
                    imageUrl: bProfileImg,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bName,
                          style: AppTypography.bodyMd.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                        if (bProfile?.statusMessage != null && bProfile!.statusMessage!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            bProfile.statusMessage!,
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

            // 3. B가 선택한 미션 내용
            if (assignedMission != null && assignedMission.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowOf(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎯 ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        assignedMission,
                        style: AppTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 4. B가 작성한 내용 (사진 및 텍스트)
            if (record != null) ...[
              FeedRecordContentBlocks(blocks: record!.content),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                child: Text(
                  '$bName님이 등록한 기록이 없습니다.',
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
