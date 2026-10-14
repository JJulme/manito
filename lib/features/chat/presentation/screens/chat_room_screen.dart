import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_message_model.dart';
import '../chat_provider.dart';
import '../widgets/chat_drawer_menu.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const ChatRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isSameDay(DateTime dt1, DateTime dt2) {
    final d1 = dt1.toLocal();
    final d2 = dt2.toLocal();
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildDateDivider(DateTime dt) {
    final localDt = dt.toLocal();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayStr = weekdays[localDt.weekday - 1];
    final dateStr = '${localDt.year}년 ${localDt.month}월 ${localDt.day}일 $weekdayStr요일';

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.isDark(context)
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          dateStr,
          style: AppTypography.bodySm.copyWith(
            color: AppColors.textSecondaryOf(context),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _handleLeaveRoom() async {
    try {
      await ref.read(chatRepositoryProvider).leaveRoom(widget.roomId);
      ref.invalidate(chatRoomsProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('채팅방 나가기 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(chatRoomDetailsProvider(widget.roomId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.roomId));
    final currentUserId = ref.watch(currentUserProvider)?.id ?? '';

    // 새 메시지가 오면 맨 아래로 스크롤
    ref.listen<AsyncValue<List<ChatMessageModel>>>(chatMessagesProvider(widget.roomId), (prev, next) {
      if (next.hasValue && (prev?.value?.length ?? 0) < (next.value?.length ?? 0)) {
        _scrollToBottom();
      }
    });

    final room = roomAsync.value;
    final title = room?.getDisplayTitle(currentUserId) ?? '채팅방';

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryOf(context),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevron_left),
          onPressed: () {
            ref.invalidate(chatRoomsProvider);
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.menu),
            tooltip: '서랍 열기',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: room != null
          ? ChatDrawerMenu(
              room: room,
              currentUserId: currentUserId,
              onLeaveRoom: _handleLeaveRoom,
            )
          : null,
      body: Column(
        children: [
          // 1. 메시지 스트림 리스트
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: messagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (err, _) => Center(child: Text('메시지를 불러올 수 없습니다: $err')),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.message_square,
                            size: 44,
                            color: AppColors.primary.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '첫 메시지를 보내 대화를 시작해보세요!',
                            style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondaryOf(context)),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (ctx, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == currentUserId;

                      // 날짜 구분선 표시 여부
                      final showDateDivider = index == 0 ||
                          !_isSameDay(messages[index - 1].createdAt, msg.createdAt);

                      // 연속 메시지 아바타 생략 여부 (이전 메시지와 작성자가 같고 같은 분에 보낸 경우)
                      bool showAvatar = true;
                      if (!isMe && index > 0) {
                        final prevMsg = messages[index - 1];
                        if (prevMsg.senderId == msg.senderId &&
                            _isSameDay(prevMsg.createdAt, msg.createdAt) &&
                            prevMsg.createdAt.minute == msg.createdAt.minute) {
                          showAvatar = false;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showDateDivider) _buildDateDivider(msg.createdAt),
                          ChatMessageBubble(
                            message: msg,
                            isMe: isMe,
                            showAvatarAndName: showAvatar,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // 2. 하단 메시지 입력바 (댓글창과 동일한 캡슐 디자인)
          ChatInputBar(
            onSendText: (text) {
              ref.read(chatMessagesProvider(widget.roomId).notifier).sendTextMessage(text);
              _scrollToBottom();
            },
            onSendImages: (images) {
              ref.read(chatMessagesProvider(widget.roomId).notifier).sendImagesMessage(images);
              _scrollToBottom();
            },
            onSendEmoticon: (emoticonFile) {
              ref.read(chatMessagesProvider(widget.roomId).notifier).sendImagesMessage([emoticonFile]);
              _scrollToBottom();
            },
          ),
        ],
      ),
    );
  }
}
