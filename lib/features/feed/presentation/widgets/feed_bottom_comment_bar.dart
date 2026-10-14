import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/features/feed/presentation/feed_provider.dart';

/// 피드 결과 화면 하단 플로팅 알약 캡슐형 댓글 바 (댓글창 입력바와 100% 동일한 외형)
class FeedBottomCommentBar extends ConsumerWidget {
  final int? targetRecordId;
  final String selectedMemberName;
  final VoidCallback onTap;

  const FeedBottomCommentBar({
    super.key,
    required this.targetRecordId,
    required this.selectedMemberName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final commentsAsync =
        targetRecordId != null
            ? ref.watch(recordCommentsProvider(targetRecordId!))
            : null;
    final commentCount = commentsAsync?.value?.length ?? 0;
    final unreadCount =
        targetRecordId != null
            ? ref.watch(recordUnreadCommentCountProvider(targetRecordId!))
            : 0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : AppColors.borderOf(context).withValues(alpha: 0.9),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                // 1. Photo Icon (댓글창 좌측 사진 첨부 버튼과 일치)
                SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                    child: Icon(
                      LucideIcons.image_plus,
                      color: AppColors.textSecondaryOf(context),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // 2. Hint Text
                Expanded(
                  child: Text(
                    '댓글을 남겨보세요.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textDisabledOf(context),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // 3. Right Section: 댓글 카운트 뱃지 (있을 경우) + 이모티콘 아이콘
                if (commentCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          unreadCount > 0
                              ? AppColors.error.withValues(alpha: 0.12)
                              : AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '댓글 $commentCount',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color:
                                unreadCount > 0
                                    ? AppColors.error
                                    : AppColors.primaryDark,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+$unreadCount',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                ],

                // Right Emoticon Icon (댓글창 우측 이모티콘 버튼과 일치)
                SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                    child: Icon(
                      LucideIcons.face_slightly_smiling,
                      color: AppColors.textSecondaryOf(context),
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
