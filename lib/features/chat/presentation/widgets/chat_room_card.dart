import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/widget/user_avatar.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/chat_room_model.dart';

class ChatRoomCard extends StatelessWidget {
  final ChatRoomModel room;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ChatRoomCard({
    super.key,
    required this.room,
    required this.currentUserId,
    required this.onTap,
    this.onLongPress,
  });

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final localDt = dt.toLocal();

    if (now.year == localDt.year && now.month == localDt.month && now.day == localDt.day) {
      final isPm = localDt.hour >= 12;
      final displayHour = localDt.hour == 0 ? 12 : (localDt.hour > 12 ? localDt.hour - 12 : localDt.hour);
      final period = isPm ? '오후' : '오전';
      final min = localDt.minute.toString().padLeft(2, '0');
      return '$period $displayHour:$min';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.year == localDt.year && yesterday.month == localDt.month && yesterday.day == localDt.day) {
      return '어제';
    }

    if (now.year == localDt.year) {
      return '${localDt.month}월 ${localDt.day}일';
    }

    return DateFormat('yyyy.MM.dd').format(localDt);
  }

  String _getMessagePreview(ChatMessageModel? lastMessage) {
    if (lastMessage == null) return '대화를 시작해보세요.';
    switch (lastMessage.type) {
      case ChatMessageType.text:
        return lastMessage.content ?? '';
      case ChatMessageType.image:
        return '📷 사진을 보냈습니다.';
      case ChatMessageType.emoticon:
        return '🥰 이모티콘을 보냈습니다.';
      case ChatMessageType.system:
        return lastMessage.content ?? '';
    }
  }

  Widget _buildAvatar(BuildContext context) {
    if (room.type == ChatRoomType.direct) {
      final other = room.getOtherMember(currentUserId);
      return UserAvatar(
        imageUrl: other?.user?.profileImageUrl,
        size: 52,
      );
    } else {
      // 그룹 아바타 (참여자 중 최대 2명 오버랩)
      final otherMembers = room.members.where((m) => m.userId != currentUserId).take(2).toList();
      if (otherMembers.isEmpty) {
        return const UserAvatar(imageUrl: null, size: 52);
      }

      if (otherMembers.length == 1) {
        return UserAvatar(imageUrl: otherMembers.first.user?.profileImageUrl, size: 52);
      }

      return SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: UserAvatar(
                imageUrl: otherMembers[0].user?.profileImageUrl,
                size: 34,
                borderWidth: 1.5,
                borderColor: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: UserAvatar(
                imageUrl: otherMembers[1].user?.profileImageUrl,
                size: 34,
                borderWidth: 1.5,
                borderColor: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = room.getDisplayTitle(currentUserId);
    final preview = _getMessagePreview(room.lastMessage);
    final timeStr = room.lastMessage != null
        ? _formatTime(room.lastMessage!.createdAt)
        : _formatTime(room.updatedAt);
    final isUnread = room.unreadCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildAvatar(context),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textPrimaryOf(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: AppTypography.bodySm.copyWith(
                            color: isUnread ? AppColors.primaryDark : AppColors.textDisabledOf(context),
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview,
                            style: AppTypography.bodyMd.copyWith(
                              color: isUnread ? AppColors.textPrimaryOf(context) : AppColors.textSecondaryOf(context),
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.statusRed,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                            alignment: Alignment.center,
                            child: Text(
                              room.unreadCount > 99 ? '99+' : room.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
