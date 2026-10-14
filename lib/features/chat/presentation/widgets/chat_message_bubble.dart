import 'package:flutter/material.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/widget/user_avatar.dart';
import '../../data/models/chat_message_model.dart';
import 'chat_emoticon_bubble.dart';
import 'chat_image_grid_bubble.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final bool showAvatarAndName;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatarAndName = true,
  });

  String _formatTime(DateTime dt) {
    final localDt = dt.toLocal();
    final isPm = localDt.hour >= 12;
    final displayHour = localDt.hour == 0 ? 12 : (localDt.hour > 12 ? localDt.hour - 12 : localDt.hour);
    final period = isPm ? '오후' : '오전';
    final min = localDt.minute.toString().padLeft(2, '0');
    return '$period $displayHour:$min';
  }

  @override
  Widget build(BuildContext context) {
    // 1. 시스템 메시지 (중앙 안내 바)
    if (message.type == ChatMessageType.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.isDark(context)
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.content ?? '',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textSecondaryOf(context),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final timeStr = _formatTime(message.createdAt);
    final hasUnread = message.unreadCount > 0;

    // 미읽음 표시 + 시간 정보 컬럼 위젯
    final metaInfoWidget = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (hasUnread)
          Text(
            message.unreadCount.toString(),
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        Text(
          timeStr,
          style: TextStyle(
            color: AppColors.textDisabledOf(context),
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );

    // 2. 메시지 본문 위젯 생성
    Widget messageContent;
    if (message.type == ChatMessageType.emoticon && message.imageUrls.isNotEmpty) {
      // 내 사진 이모티콘 (투명 배경)
      messageContent = ChatEmoticonBubble(imageUrl: message.imageUrls.first);
    } else if (message.type == ChatMessageType.image && message.imageUrls.isNotEmpty) {
      // 사진 묶음 그리드
      messageContent = ChatImageGridBubble(imageUrls: message.imageUrls, isMe: isMe);
    } else {
      // 일반 텍스트 말풍선
      final isDark = AppColors.isDark(context);
      final bubbleBgColor = isMe
          ? AppColors.primary
          : (isDark ? AppColors.darkCard : const Color(0xFFF0F1F5));
      final textColor = isMe
          ? const Color(0xFF1E1E24)
          : AppColors.textPrimaryOf(context);

      messageContent = Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleBgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: isMe ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: SelectableText(
          message.content ?? '',
          style: AppTypography.bodyMd.copyWith(
            color: textColor,
            fontSize: 15,
            height: 1.35,
          ),
        ),
      );
    }

    // 3. 내가 보낸 메시지 레이아웃 (우측 정렬)
    if (isMe) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            metaInfoWidget,
            const SizedBox(width: 6),
            Flexible(child: messageContent),
          ],
        ),
      );
    }

    // 4. 상대방이 보낸 메시지 레이아웃 (좌측 정렬)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatarAndName)
            UserAvatar(imageUrl: message.sender?.profileImageUrl, size: 38)
          else
            const SizedBox(width: 38),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showAvatarAndName) ...[
                  Text(
                    message.sender?.name ?? '사용자',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondaryOf(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(child: messageContent),
                    const SizedBox(width: 6),
                    metaInfoWidget,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
