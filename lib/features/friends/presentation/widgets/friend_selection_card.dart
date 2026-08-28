import 'package:flutter/material.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widget/user_avatar.dart';

/// 친구 선택 리스트 카드 (방 개설 및 대기실 친구 추가 모달 공용 위젯)
class FriendSelectionCard extends StatelessWidget {
  final UserModel friend;
  final bool isSelected;
  final VoidCallback onToggle;

  const FriendSelectionCard({
    super.key,
    required this.friend,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderOf(context),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: AppColors.cardShadowOf(context),
        ),
        child: Row(
          children: [
            // 1. Clean Circular Profile Avatar (선택 효과 없는 정갈한 원형 아바타)
            UserAvatar(
              imageUrl: friend.profileImageUrl,
              size: 44,
            ),
            const SizedBox(width: 12),

            // 2. Name & Status Message / Code
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name.isNotEmpty ? friend.name : '알 수 없는 요원',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    friend.statusMessage?.isNotEmpty == true
                        ? friend.statusMessage!
                        : '코드: ${friend.uniqueCode.isNotEmpty ? friend.uniqueCode : "-"}',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 3. Circular Selection Indicator (우측 원형 체크 버튼)
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderOf(context),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Color(0xFF1E1E24))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
