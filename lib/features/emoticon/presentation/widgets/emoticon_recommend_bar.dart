import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter/services.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/features/emoticon/data/models/custom_emoticon_model.dart';

/// 댓글 입력창 상단에 떠 있는 카드 형태로 표시되는 이모티콘 추천 팝업 바
class EmoticonRecommendBar extends StatelessWidget {
  final List<CustomEmoticonModel> emoticons;
  final ValueChanged<CustomEmoticonModel> onSelected;
  final VoidCallback? onDismiss;

  const EmoticonRecommendBar({
    super.key,
    required this.emoticons,
    required this.onSelected,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (emoticons.isEmpty) return const SizedBox.shrink();

    final isDark = AppColors.isDark(context);
    final cardBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      height: 66,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : AppColors.borderOf(context).withValues(alpha: 0.9),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Row(
          children: [
            // 가로 스크롤 썸네일 리스트
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                scrollDirection: Axis.horizontal,
                itemCount: emoticons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final emoticon = emoticons[idx];
                  final file = File(emoticon.localImagePath);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelected(emoticon);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLowOf(context),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: AppColors.borderOf(context).withValues(alpha: 0.7),
                          width: 0.8,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: file.existsSync()
                            ? Image.file(
                                file,
                                fit: BoxFit.cover,
                                cacheWidth: 150, // 50 * 3
                              )
                            : Container(
                                color: AppColors.surfaceLowOf(context),
                                child: Icon(
                                  LucideIcons.image_off,
                                  size: 20,
                                  color: AppColors.textDisabledOf(context),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 닫기 (X) 버튼
            if (onDismiss != null) ...[
              Padding(
                padding: const EdgeInsets.only(right: 8, left: 2),
                child: InkWell(
                  onTap: onDismiss,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLowOf(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.x,
                      size: 15,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
