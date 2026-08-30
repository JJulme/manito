import 'package:flutter/material.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/util/game_time_util.dart';
import 'package:manito/features/rooms/presentation/widgets/lobby_duration_picker_modal.dart';
import 'package:manito/features/rooms/presentation/widgets/lobby_edit_title_dialog.dart';

/// 대기실 옵션 설정 카드 (제목, 미션 카테고리, 마감 시간)
class LobbyOptionsCard extends StatelessWidget {
  final RoomModel room;
  final bool isHost;
  final ValueChanged<String>? onCategoryChanged;

  const LobbyOptionsCard({
    super.key,
    required this.room,
    required this.isHost,
    this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final category = room.missionCategory?.toLowerCase() ?? 'daily';
    final deadline = room.gameEndTime ?? GameTimeUtil.calculateCeiledDeadline(minutesToAdd: 30);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppColors.cardShadowOf(context),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: AppColors.isDark(context) ? AppColors.primary : AppColors.primaryDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '마니또 옵션',
                    style: AppTypography.titleSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ],
              ),
              if (isHost)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.isDark(context)
                        ? AppColors.darkPrimaryLight
                        : AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '방장',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDarkOf(context),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // A. Room Title Setting
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('제목', style: AppTypography.labelMd.copyWith(color: AppColors.textSecondaryOf(context))),
              if (isHost)
                InkWell(
                  onTap: () => LobbyEditTitleDialog.show(context, roomId: room.roomId, currentTitle: room.title),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 14, color: AppColors.textSecondaryOf(context)),
                        const SizedBox(width: 4),
                        Text(
                          '수정',
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
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowOf(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Text(
              room.title,
              style: AppTypography.bodyMd.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // B. Mission Category Setting
          Text('미션 카테고리', style: AppTypography.labelMd.copyWith(color: AppColors.textSecondaryOf(context))),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildCategoryButton(context, '일상 (Daily)', 'daily', category == 'daily', isEnabled: isHost),
              const SizedBox(width: 8),
              _buildCategoryButton(context, '학교 (School)', 'school', category == 'school', isEnabled: isHost),
              const SizedBox(width: 8),
              _buildCategoryButton(context, '직장 (Work)', 'work', category == 'work', isEnabled: isHost),
            ],
          ),
          const SizedBox(height: 16),

          // C. Game Duration & Ceiled Deadline Setting
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('마감 시간', style: AppTypography.labelMd.copyWith(color: AppColors.textSecondaryOf(context))),
              if (isHost)
                InkWell(
                  onTap: () => LobbyDurationPickerModal.show(context, roomId: room.roomId, currentEndTime: room.gameEndTime),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondaryOf(context)),
                        const SizedBox(width: 4),
                        Text(
                          '설정',
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
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowOf(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.alarm_on_rounded,
                      size: 18,
                      color: AppColors.isDark(context) ? AppColors.primary : AppColors.primaryDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '마감 시간: ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}',
                      style: AppTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.isDark(context)
                        ? AppColors.darkPrimaryLight
                        : AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${deadline.month}/${deadline.day}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDarkOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(
    BuildContext context,
    String label,
    String value,
    bool isSelected, {
    bool isEnabled = true,
  }) {
    return Expanded(
      child: InkWell(
        onTap: isEnabled ? () => onCategoryChanged?.call(value) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceLowOf(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primaryDark : AppColors.borderOf(context),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF1E1E24) : AppColors.textSecondaryOf(context),
            ),
          ),
        ),
      ),
    );
  }
}
