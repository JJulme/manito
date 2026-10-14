import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/widget/user_avatar.dart';
import '../../data/models/chat_room_model.dart';

class ChatDrawerMenu extends ConsumerWidget {
  final ChatRoomModel room;
  final String currentUserId;
  final VoidCallback onLeaveRoom;

  const ChatDrawerMenu({
    super.key,
    required this.room,
    required this.currentUserId,
    required this.onLeaveRoom,
  });

  void _showLeaveConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('채팅방 나가기', style: AppTypography.headlineMd),
        content: const Text(
          '채팅방을 나가면 대화 내용이 모두 삭제되고 채팅 목록에서도 삭제됩니다.\n\n정말 나가시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Close drawer
              onLeaveRoom();
            },
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMembers = room.members.where((m) => m.isActive).toList();

    return Drawer(
      backgroundColor: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 헤더 (서랍 타이틀)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    '채팅방 서랍',
                    style: AppTypography.titleLg.copyWith(
                      color: AppColors.textPrimaryOf(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 2. 대화 참여자 목록 섹션
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    '대화상대',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${activeMembers.length}',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: activeMembers.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                itemBuilder: (ctx, index) {
                  final member = activeMembers[index];
                  final isMe = member.userId == currentUserId;

                  return ListTile(
                    leading: UserAvatar(imageUrl: member.user?.profileImageUrl, size: 40),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.user?.name ?? '사용자',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textPrimaryOf(context),
                              fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '나',
                              style: TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // 3. 하단 나가기 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ListTile(
                leading: const Icon(LucideIcons.log_out, color: AppColors.statusRed),
                title: const Text(
                  '채팅방 나가기',
                  style: TextStyle(
                    color: AppColors.statusRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => _showLeaveConfirmDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
