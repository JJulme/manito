import 'package:flutter/material.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/widget/user_avatar.dart';

/// 마니또 의심자 선택 카드 및 바텀시트
class SuspectSelectionCard extends StatelessWidget {
  final List<RoomMemberModel> otherMembers;
  final String? selectedSuspectId;
  final bool hasError;
  final ValueChanged<String> onSuspectSelected;

  const SuspectSelectionCard({
    super.key,
    required this.otherMembers,
    required this.selectedSuspectId,
    this.hasError = false,
    required this.onSuspectSelected,
  });

  void _showModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderOf(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '친구 선택',
                style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimaryOf(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (otherMembers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      '선택 가능한 참가자가 없습니다.',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondaryOf(context)),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: otherMembers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final m = otherMembers[idx];
                      final p = m.userProfile;
                      final pImg = p?.profileImageUrl;
                      final statusMsg = p?.statusMessage;
                      final isSelected = m.userId == selectedSuspectId;

                      return InkWell(
                        onTap: () {
                          onSuspectSelected(m.userId);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (AppColors.isDark(context)
                                    ? AppColors.darkPrimaryLight
                                    : AppColors.primaryLight.withValues(alpha: 0.3))
                                : AppColors.surfaceOf(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.borderOf(context),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              UserAvatar(
                                imageUrl: pImg,
                                size: 40,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p?.name ?? '요원',
                                      style: AppTypography.titleSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimaryOf(context),
                                      ),
                                    ),
                                    if (statusMsg != null && statusMsg.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        statusMsg,
                                        style: AppTypography.bodySm.copyWith(
                                          color: AppColors.textSecondaryOf(context),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: AppColors.primaryDark, size: 22),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    RoomMemberModel? selectedMember;
    if (selectedSuspectId != null) {
      for (final m in otherMembers) {
        if (m.userId == selectedSuspectId) {
          selectedMember = m;
          break;
        }
      }
    }
    final profile = selectedMember?.userProfile;
    final profileImg = profile?.profileImageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showModal(context),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: hasError
                  ? AppColors.statusRed.withValues(alpha: 0.05)
                  : (Theme.of(context).cardTheme.color ?? AppColors.cardOf(context)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasError
                    ? AppColors.statusRed
                    : (selectedMember != null ? AppColors.primary : AppColors.borderOf(context)),
                width: (hasError || selectedMember != null) ? 1.8 : 1.0,
              ),
              boxShadow: AppColors.cardShadowOf(context),
            ),
            child: Row(
              children: [
                UserAvatar(
                  imageUrl: selectedMember != null ? profileImg : null,
                  size: 44,
                  fallbackIcon: selectedMember != null ? Icons.person : Icons.person_search_rounded,
                  fallbackIconColor: (selectedMember == null && hasError)
                      ? AppColors.statusRed
                      : AppColors.textSecondaryOf(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedMember != null
                            ? (profile?.name ?? '요원')
                            : '친구 선택',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: hasError
                              ? AppColors.statusRed
                              : (selectedMember != null ? AppColors.textPrimaryOf(context) : AppColors.textSecondaryOf(context)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedMember != null
                            ? (profile?.statusMessage?.isNotEmpty == true
                                ? profile!.statusMessage!
                                : '마니또로 지목된 요원')
                            : '나의 마니또로 의심되는 친구를 선택하세요',
                        style: AppTypography.bodySm.copyWith(
                          color: hasError ? AppColors.statusRed : AppColors.textSecondaryOf(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: hasError ? AppColors.statusRed : AppColors.textSecondaryOf(context),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (hasError)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text(
              '⚠️ 마니또로 의심되는 친구를 선택해 주세요.',
              style: TextStyle(color: AppColors.statusRed, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
