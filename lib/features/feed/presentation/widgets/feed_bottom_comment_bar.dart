import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/features/feed/presentation/feed_provider.dart';

/// 피드 결과 화면 하단 고정 댓글 바
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
    final commentsAsync = targetRecordId != null
        ? ref.watch(recordCommentsProvider(targetRecordId!))
        : null;
    final commentCount = commentsAsync?.value?.length ?? 0;
    final unreadCount = targetRecordId != null
        ? ref.watch(recordUnreadCommentCountProvider(targetRecordId!))
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
        border: Border(top: BorderSide(color: AppColors.borderOf(context), width: 1)),
        boxShadow: AppColors.cardShadowOf(context),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowOf(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.borderOf(context),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: unreadCount > 0 ? AppColors.error : AppColors.primaryDark,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: -2,
                          right: -3,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '댓글을 남겨보세요.',
                      style: AppTypography.bodySm.copyWith(color: AppColors.textDisabledOf(context)),
                    ),
                  ),
                  if (commentCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: unreadCount > 0
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
                              color: unreadCount > 0 ? AppColors.error : AppColors.primaryDark,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
