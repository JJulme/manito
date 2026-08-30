import 'package:flutter/material.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/widget/user_avatar.dart';

/// 여러 사용자의 아바타가 겹쳐서 표시되는 공통 위젯
class OverlappingAvatars extends StatelessWidget {
  final List<RoomMemberModel> members;
  final int maxAvatars;
  final double avatarSize;
  final double overlapOffset;
  final bool showCountText;
  final String countTextSuffix;
  final Color? borderColor;

  const OverlappingAvatars({
    super.key,
    required this.members,
    this.maxAvatars = 4,
    this.avatarSize = 28,
    double? overlapOffset,
    this.showCountText = true,
    this.countTextSuffix = '명 참여 중',
    this.borderColor,
  }) : overlapOffset = overlapOffset ?? (avatarSize * 0.65);

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    final displayMembers = members.take(maxAvatars).toList();
    final extraCount = members.length - maxAvatars;
    final cardBg = borderColor ??
        Theme.of(context).cardTheme.color ??
        AppColors.cardOf(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: (displayMembers.length * overlapOffset) +
              (extraCount > 0 ? avatarSize : (avatarSize - overlapOffset)),
          height: avatarSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < displayMembers.length; i++)
                Positioned(
                  left: i * overlapOffset,
                  child: UserAvatar(
                    imageUrl: displayMembers[i].userProfile?.profileImageUrl,
                    size: avatarSize,
                    borderWidth: avatarSize >= 28 ? 2 : 1.5,
                    borderColor: cardBg,
                    showShadow: true,
                    fallbackIconSize: avatarSize * 0.5,
                  ),
                ),
              if (extraCount > 0)
                Positioned(
                  left: displayMembers.length * overlapOffset,
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceLowOf(context),
                      border: Border.all(
                        color: cardBg,
                        width: avatarSize >= 28 ? 2 : 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+$extraCount',
                      style: TextStyle(
                        fontSize: avatarSize >= 28 ? 10 : 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showCountText) ...[
          const SizedBox(width: 8),
          Text(
            '${members.length}$countTextSuffix',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ],
      ],
    );
  }
}
