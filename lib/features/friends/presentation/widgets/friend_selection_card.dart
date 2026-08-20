import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

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
    final hasImg = friend.profileImageUrl != null && friend.profileImageUrl!.isNotEmpty;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryDark : AppColors.border,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            // 1. Clean Circular Profile Avatar (선택 효과 없는 정갈한 원형 아바타)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceLow,
                border: Border.all(
                  color: AppColors.border,
                  width: 1.0,
                ),
              ),
              child: ClipOval(
                child: hasImg
                    ? (friend.profileImageUrl!.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: friend.profileImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppColors.surface),
                            errorWidget: (_, __, ___) => const Icon(Icons.person, color: AppColors.textSecondary),
                          )
                        : Image.asset(friend.profileImageUrl!, fit: BoxFit.cover))
                    : const Icon(Icons.person, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 12),

            // 2. Name & Status Message / Code
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name.isNotEmpty ? friend.name : '알 수 없는 요원',
                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    friend.statusMessage?.isNotEmpty == true
                        ? friend.statusMessage!
                        : '코드: ${friend.uniqueCode.isNotEmpty ? friend.uniqueCode : "-"}',
                    style: AppTypography.bodySm,
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
                  color: isSelected ? AppColors.primaryDark : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: AppColors.textPrimary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
