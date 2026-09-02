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
import '../../../../core/util/text_sanitizer.dart';
import '../../../../core/widget/user_avatar.dart';
import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../emoticon/data/custom_emoticon_repository.dart';
import '../../../emoticon/data/models/custom_emoticon_model.dart';
import '../../../emoticon/presentation/screens/custom_emoticon_manage_screen.dart';
import '../../../emoticon/presentation/widgets/emoticon_picker_panel.dart';
import '../../../emoticon/presentation/widgets/emoticon_recommend_bar.dart';
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
  final FocusNode _focusNode = FocusNode();
  RealtimeChannel? _commentChannel;
  File? _selectedImage;
  bool _isEmoticonSelected = false;
  bool _isSending = false;
  bool _isPickingImage = false;

  /// 이모티콘 패널 열림 여부 및 키보드 높이
  bool _isEmoticonPickerOpen = false;
  double _keyboardHeight = 280.0;

  /// 이모티콘 추천 매칭 결과
  List<CustomEmoticonModel> _matchedEmoticons = [];
  /// 현재 매칭된 키워드 (텍스트 정리용)
  String _matchedKeyword = '';
  /// 사용자가 X 버튼으로 닫은 키워드 (단어가 바뀔 때까지 추천 숨김)
  String? _dismissedKeyword;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
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

  void _onFocusChanged() {
    if (_focusNode.hasFocus && _isEmoticonPickerOpen) {
      setState(() {
        _isEmoticonPickerOpen = false;
      });
    }
  }

  void _subscribeToComments() {
    final supabase = Supabase.instance.client;
    _commentChannel = supabase
        .channel('public:comments:${widget.recordId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'record_id',
            value: widget.recordId,
          ),
          callback: (payload) {
            ref.invalidate(recordCommentsProvider(widget.recordId));
            ref.invalidate(roomRecordsProvider(widget.roomId));

            final currentUserId = ref.read(currentUserProvider)?.id;
            final isNotMe = payload.newRecord['user_id'] != currentUserId;

            if (isNotMe) {
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
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  /// 텍스트 변경 시 마지막 어절 기반 이모티콘 키워드 매칭
  void _onTextChanged() {
    final text = _controller.text;
    if (text.trim().isEmpty) {
      if (_matchedEmoticons.isNotEmpty) {
        setState(() {
          _matchedEmoticons = [];
          _matchedKeyword = '';
        });
      }
      return;
    }

    // 마지막 어절(공백 기준) 추출
    final words = text.split(RegExp(r'\s+'));
    final lastWord = words.isNotEmpty ? words.last.trim() : '';
    if (lastWord.isEmpty || lastWord == _dismissedKeyword) {
      if (_matchedEmoticons.isNotEmpty) {
        setState(() {
          _matchedEmoticons = [];
          _matchedKeyword = '';
        });
      }
      return;
    }

    // 단어가 바뀌었으면 닫았던 키워드 상태 리셋
    if (_dismissedKeyword != null && _dismissedKeyword != lastWord) {
      _dismissedKeyword = null;
    }

    // 비동기 검색 수행
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    ref.read(customEmoticonRepositoryProvider).searchByKeyword(userId, lastWord).then((results) {
      if (!mounted) return;
      setState(() {
        _matchedEmoticons = results;
        _matchedKeyword = lastWord;
      });
    });
  }

  /// 추천 바 닫기 (X 버튼 탭 시)
  void _onDismissRecommendation() {
    setState(() {
      _dismissedKeyword = _matchedKeyword;
      _matchedEmoticons = [];
    });
  }

  /// 추천 바에서 이모티콘 선택 시 처리
  void _onEmoticonSelected(CustomEmoticonModel emoticon) {
    final file = File(emoticon.localImagePath);
    if (!file.existsSync()) return;

    setState(() {
      _selectedImage = file;
      _isEmoticonSelected = true;
    });

    // 텍스트 정리: 키워드만 단독 입력된 경우 텍스트 클리어, 복합 문장이면 유지
    final text = _controller.text.trim();
    if (text == _matchedKeyword) {
      _controller.clear();
    }

    // 추천 바 닫기
    setState(() {
      _matchedEmoticons = [];
      _matchedKeyword = '';
    });
  }

  void _toggleEmoticonPicker() {
    if (_isEmoticonPickerOpen) {
      setState(() => _isEmoticonPickerOpen = false);
      _focusNode.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
      setState(() => _isEmoticonPickerOpen = true);
    }
  }

  void _openManageScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomEmoticonManageScreen()),
    );
  }

  void _dismissPickerAndKeyboard() {
    if (_isEmoticonPickerOpen) {
      setState(() => _isEmoticonPickerOpen = false);
    }
    FocusScope.of(context).unfocus();
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
          _isEmoticonSelected = false;
        });
      }
    } catch (e, s) {
      AppLogger.e('Error picking comment image: $e', tag: 'FEED', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진을 불러올 수 없습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _sendComment() async {
    final text = TextSanitizer.sanitizeMultiLine(_controller.text);
    if ((text.isEmpty && _selectedImage == null) || _isSending) return;

    setState(() => _isSending = true);
    try {
      String? uploadedImageUrl;

      // 1. 첨부된 이미지가 있으면 업로드
      if (_selectedImage != null) {
        final imageService = ref.read(imageServiceProvider);
        final compressedFile = await imageService.compressImage(_selectedImage!);
        final prefix = _isEmoticonSelected ? 'emoticon' : 'comment';
        final fileName = 'comments/${prefix}_${widget.recordId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
          'is_emoticon': _isEmoticonSelected,
          'text_length': text.length,
        },
      );

      _controller.clear();
      setState(() {
        _selectedImage = null;
        _isEmoticonSelected = false;
      });

      ref.invalidate(recordCommentsProvider(widget.recordId));
      ref.invalidate(roomRecordsProvider(widget.roomId));
    } catch (e, s) {
      if (mounted) {
        AppLogger.e('댓글 작성 실패', error: e, stackTrace: s);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글 작성에 실패했습니다. 다시 시도해 주세요.')),
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
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    if (viewInsetsBottom > 0 && viewInsetsBottom != _keyboardHeight) {
      _keyboardHeight = viewInsetsBottom;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        bottom: _isEmoticonPickerOpen ? 0 : viewInsetsBottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _dismissPickerAndKeyboard,
            child: Padding(
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
          ),
          Divider(height: 1, color: AppColors.dividerOf(context)),

          // Comments List
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismissPickerAndKeyboard,
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (scrollInfo is ScrollStartNotification && scrollInfo.dragDetails != null) {
                    _dismissPickerAndKeyboard();
                  }
                  return false;
                },
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

                               // 2. 첨부 사진 카드 / 이모티콘 스티커 (상단 배치)
                              if (hasImage) ...[
                                const SizedBox(height: 6),
                                Builder(
                                  builder: (context) {
                                    final isEmoticon = comment.imageUrl!.contains('emoticon');

                                    if (isEmoticon) {
                                      // 이모티콘: 카톡 스타일의 아담한 110x110 스티커 렌더링
                                      return GestureDetector(
                                        onTap: () => _openFullScreenImage(context, comment.imageUrl!),
                                        child: Container(
                                          width: 110,
                                          height: 110,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.08),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: CachedNetworkImage(
                                              imageUrl: comment.imageUrl!,
                                              fit: BoxFit.cover,
                                              fadeInDuration: const Duration(milliseconds: 180),
                                              fadeOutDuration: const Duration(milliseconds: 150),
                                              placeholder: (context, url) => Container(
                                                width: 110,
                                                height: 110,
                                                color: AppColors.surfaceLowOf(context).withValues(alpha: 0.3),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                width: 110,
                                                height: 110,
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
                                      );
                                    }

                                    // 일반 갤러리 사진: 큼직한 사진 뷰어 카드 렌더링
                                    return GestureDetector(
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
                                            fadeInDuration: const Duration(milliseconds: 180),
                                            fadeOutDuration: const Duration(milliseconds: 150),
                                            placeholder: (context, url) => Container(
                                              height: 140,
                                              width: 180,
                                              color: AppColors.surfaceLowOf(context).withValues(alpha: 0.5),
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
                                    );
                                  },
                                ),
                              ],

                              // 3. 텍스트 본문 (하단 배치)
                              if (comment.content.isNotEmpty) ...[
                                SizedBox(height: hasImage ? 6 : 4),
                                Text(
                                  comment.content,
                                  style: AppTypography.bodyMd.copyWith(
                                    color: AppColors.textPrimaryOf(context),
                                    height: 1.4,
                                    fontSize: 14,
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
        ),
      ),

          // 이모티콘 추천 바 (키워드 매칭 시 표시, X 버튼으로 닫기 가능)
          if (_matchedEmoticons.isNotEmpty)
            EmoticonRecommendBar(
              emoticons: _matchedEmoticons,
              onSelected: _onEmoticonSelected,
              onDismiss: _onDismissRecommendation,
            ),

          // Floating Input Bar Area
          SafeArea(
            top: false,
            bottom: !_isEmoticonPickerOpen && viewInsetsBottom == 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Preview Floating Card (if image selected)
                if (_selectedImage != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 8),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: AppColors.isDark(context) ? 0.35 : 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              width: 58,
                              height: 58,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedImage = null;
                              _isEmoticonSelected = false;
                            }),
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

                // All-in-One Floating Pill Capsule (FeedBottomCommentBar와 100% 동일)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.isDark(context)
                          ? const Color(0xFF2C2C2E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.isDark(context)
                            ? Colors.white.withValues(alpha: 0.12)
                            : AppColors.borderOf(context).withValues(alpha: 0.9),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: AppColors.isDark(context) ? 0.3 : 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // 1. Photo Attachment Button
                        IconButton(
                          onPressed: _isSending || _isPickingImage ? null : _pickImage,
                          icon: _isPickingImage
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                                )
                              : Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: AppColors.textSecondaryOf(context),
                                  size: 22,
                                ),
                          tooltip: '사진 첨부',
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                        ),
                        const SizedBox(width: 4),

                        // 2. Seamless Borderless TextField
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimaryOf(context),
                            ),
                            onTap: () {
                              if (_isEmoticonPickerOpen) {
                                setState(() => _isEmoticonPickerOpen = false);
                              }
                            },
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: '댓글을 남겨보세요.',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: AppColors.textDisabledOf(context),
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),

                        // 3. Right Action Button ([😀] ↔ [✈️] / Loading)
                        if (_isSending)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                            ),
                          )
                        else if (hasContentOrImage)
                          IconButton(
                            onPressed: _sendComment,
                            icon: const Icon(
                              Icons.send_rounded,
                              color: AppColors.primaryDark,
                              size: 22,
                            ),
                            tooltip: '전송',
                            splashRadius: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                          )
                        else
                          IconButton(
                            onPressed: _toggleEmoticonPicker,
                            icon: Icon(
                              Icons.emoji_emotions_outlined,
                              color: _isEmoticonPickerOpen
                                  ? AppColors.primary
                                  : AppColors.textSecondaryOf(context),
                              size: 24,
                            ),
                            tooltip: '이모티콘',
                            splashRadius: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 이모티콘 선택 패널 (키보드 높이만큼 표시)
          if (_isEmoticonPickerOpen)
            EmoticonPickerPanel(
              height: _keyboardHeight,
              onSelected: _onEmoticonSelected,
              onOpenManageScreen: _openManageScreen,
            ),
        ],
      ),
    );
  }
}
