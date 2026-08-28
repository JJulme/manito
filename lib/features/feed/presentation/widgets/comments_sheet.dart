import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/image/image_service.dart';
import '../../../../core/image/image_source_picker_modal.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers.dart';
import '../../../../core/util/app_logger.dart';
import '../../../../core/widget/user_avatar.dart';
import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_service.dart';
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
  File? _selectedImage;
  bool _isSending = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _subscribeToComments();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logEvent(
        AnalyticsEvent.commentSheetOpen,
        screenName: 'CommentsSheet',
        properties: {
          'record_id': widget.recordId,
          'room_id': widget.roomId,
        },
      );
    });
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

  Future<void> _pickImage() async {
    if (_isPickingImage || _isSending) return;

    final source = await showImageSourcePickerModal(context);
    if (source == null) return;

    setState(() => _isPickingImage = true);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (e, s) {
      AppLogger.e('Error picking comment image: $e', tag: 'FEED', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 선택 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if ((text.isEmpty && _selectedImage == null) || _isSending) return;

    setState(() => _isSending = true);
    try {
      String? uploadedImageUrl;

      // 1. 첨부된 이미지가 있으면 업로드
      if (_selectedImage != null) {
        final imageService = ref.read(imageServiceProvider);
        final compressedFile = await imageService.compressImage(_selectedImage!);
        final fileName = 'comments/comment_${widget.recordId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        uploadedImageUrl = await imageService.uploadImage(
          file: compressedFile,
          bucket: 'records',
          fileName: fileName,
        );
      }

      // 2. 댓글 등록
      await ref.read(feedRepositoryProvider).createComment(
            recordId: widget.recordId,
            content: text,
            imageUrl: uploadedImageUrl,
          );

      ref.read(analyticsServiceProvider).logEvent(
        AnalyticsEvent.commentCreate,
        screenName: 'CommentsSheet',
        properties: {
          'record_id': widget.recordId,
          'room_id': widget.roomId,
          'has_image': uploadedImageUrl != null,
          'text_length': text.length,
        },
      );

      _controller.clear();
      setState(() {
        _selectedImage = null;
      });

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

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.9),
        barrierDismissible: true,
        pageBuilder: (ctx, _, __) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(recordCommentsProvider(widget.recordId));
    final hasContentOrImage = _controller.text.trim().isNotEmpty || _selectedImage != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title ?? '댓글',
                  style: AppTypography.headlineMd.copyWith(color: AppColors.textPrimaryOf(context)),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.textSecondaryOf(context)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.dividerOf(context)),

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
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (ctx, idx) {
                    final comment = comments[idx];
                    final author = comment.author;
                    final isMe = comment.userId == currentUserId;
                    final hasImage = comment.imageUrl != null && comment.imageUrl!.isNotEmpty;

                    final avatarWidget = UserAvatar(
                      imageUrl: author?.profileImageUrl,
                      size: 38,
                      fallbackIconSize: 20,
                    );

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        avatarWidget,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. 닉네임 + '나' 뱃지 + 작성 시간
                              Row(
                                children: [
                                  Text(
                                    author?.name ?? '요원',
                                    style: AppTypography.titleSmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textPrimaryOf(context),
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: AppColors.primary.withValues(alpha: 0.35),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        '나',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.isDark(context) ? AppColors.primary : AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 6),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textDisabledOf(context),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    timeago.format(comment.createdAt, locale: 'ko'),
                                    style: AppTypography.labelSm.copyWith(
                                      color: AppColors.textSecondaryOf(context),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),

                              // 2. 텍스트 본문
                              if (comment.content.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  comment.content,
                                  style: AppTypography.bodyMd.copyWith(
                                    color: AppColors.textPrimaryOf(context),
                                    height: 1.4,
                                    fontSize: 14,
                                  ),
                                ),
                              ],

                              // 3. 첨부 사진 카드
                              if (hasImage) ...[
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _openFullScreenImage(context, comment.imageUrl!),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        maxWidth: 220,
                                        maxHeight: 200,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLowOf(context),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.borderOf(context),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl: comment.imageUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          height: 120,
                                          width: 160,
                                          color: AppColors.surfaceLowOf(context),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          height: 80,
                                          width: 120,
                                          color: AppColors.surfaceLowOf(context),
                                          child: Center(
                                            child: Icon(
                                              Icons.broken_image_rounded,
                                              color: AppColors.textDisabledOf(context),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
              border: Border(top: BorderSide(color: AppColors.borderOf(context))),
              boxShadow: AppColors.cardShadowOf(context),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Preview Bar (if image selected)
                  if (_selectedImage != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _selectedImage!,
                              width: 58,
                              height: 58,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImage = null),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Input Row
                  Row(
                    children: [
                      // Photo Attachment Button
                      IconButton(
                        onPressed: _isSending || _isPickingImage ? null : _pickImage,
                        icon: _isPickingImage
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                              )
                            : Icon(Icons.add_photo_alternate_outlined, color: AppColors.textSecondaryOf(context), size: 24),
                        tooltip: '사진 첨부',
                      ),
                      const SizedBox(width: 4),

                      // Text Field
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(color: AppColors.textPrimaryOf(context)),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: '댓글을 남겨보세요.',
                            hintStyle: TextStyle(color: AppColors.textDisabledOf(context)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: AppColors.borderOf(context)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: AppColors.borderOf(context)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            filled: true,
                            fillColor: AppColors.surfaceOf(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Send Button
                      IconButton(
                        onPressed: _isSending || !hasContentOrImage ? null : _sendComment,
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                              )
                            : Icon(
                                Icons.send_rounded,
                                color: hasContentOrImage ? AppColors.primaryDark : AppColors.textDisabledOf(context),
                              ),
                      ),
                    ],
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
