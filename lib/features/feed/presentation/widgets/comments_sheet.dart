import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers.dart';
import '../feed_provider.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  final int recordId;
  final String roomId;
  final String? title;

  const CommentsSheet({
    super.key,
    required this.recordId,
    required this.roomId,
    this.title,
  });

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  RealtimeChannel? _commentChannel;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _subscribeToComments();
    Future.microtask(() {
      ref.read(feedRepositoryProvider).markRecordCommentsAsRead(widget.recordId).then((_) {
        if (mounted) {
          ref.invalidate(unreadCommentSummaryProvider);
        }
      });
    });
  }

  void _subscribeToComments() {
    final supabase = Supabase.instance.client;
    _commentChannel = supabase
        .channel('comments-sheet-${widget.recordId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'record_id',
            value: widget.recordId,
          ),
          callback: (payload) {
            if (mounted) {
              ref.invalidate(recordCommentsProvider(widget.recordId));
              ref.invalidate(roomRecordsProvider(widget.roomId));
              ref.read(feedRepositoryProvider).markRecordCommentsAsRead(widget.recordId).then((_) {
                if (mounted) {
                  ref.invalidate(unreadCommentSummaryProvider);
                }
              });
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _commentChannel?.unsubscribe();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await ref.read(feedRepositoryProvider).createComment(
            recordId: widget.recordId,
            content: text,
          );
      _controller.clear();
      ref.invalidate(recordCommentsProvider(widget.recordId));
      ref.invalidate(roomRecordsProvider(widget.roomId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 작성 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(recordCommentsProvider(widget.recordId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title ?? '댓글', style: AppTypography.headlineMd),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Comments List
          Expanded(
            child: commentsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(child: Text('댓글 로드 실패: $err')),
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppColors.textDisabled),
                        SizedBox(height: 8),
                        Text('아직 작성된 댓글이 없습니다.\n첫 번째 소감을 남겨보세요!',
                            textAlign: TextAlign.center, style: AppTypography.bodySm),
                      ],
                    ),
                  );
                }

                final currentUserId = ref.watch(currentUserProvider)?.id;

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final comment = comments[idx];
                    final author = comment.author;
                    final isMe = comment.userId == currentUserId;

                    final avatarWidget = Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                      ),
                      child: ClipOval(
                        child: (author?.profileImageUrl != null && author!.profileImageUrl!.isNotEmpty)
                            ? (author.profileImageUrl!.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: author.profileImageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: AppColors.surface),
                                    errorWidget: (_, __, ___) => const Icon(Icons.person, size: 20, color: AppColors.textSecondary),
                                  )
                                : Image.asset(author.profileImageUrl!, fit: BoxFit.cover))
                            : const Icon(Icons.person, size: 20, color: AppColors.textSecondary),
                      ),
                    );

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        avatarWidget,
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? AppColors.primaryLight.withValues(alpha: 0.35)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isMe
                                    ? AppColors.primaryDark.withValues(alpha: 0.4)
                                    : AppColors.border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      author?.name ?? '요원',
                                      style: AppTypography.titleSmall.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      timeago.format(comment.createdAt, locale: 'ko'),
                                      style: AppTypography.labelSm.copyWith(color: AppColors.textDisabled, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(comment.content, style: AppTypography.bodyMd),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppColors.border)),
              boxShadow: AppColors.cardShadow,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: '댓글을 남겨보세요.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _sendComment,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                          )
                        : const Icon(Icons.send_rounded, color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
