import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:manito/core/image/image_source_picker_modal.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:manito/features/emoticon/data/custom_emoticon_repository.dart';
import 'package:manito/features/emoticon/data/models/custom_emoticon_model.dart';
import 'package:manito/features/emoticon/presentation/screens/custom_emoticon_manage_screen.dart';
import 'package:manito/features/emoticon/presentation/widgets/emoticon_picker_panel.dart';
import 'package:manito/features/emoticon/presentation/widgets/emoticon_recommend_bar.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  final ValueChanged<String> onSendText;
  final ValueChanged<List<File>> onSendImages;
  final ValueChanged<File> onSendEmoticon;

  const ChatInputBar({
    super.key,
    required this.onSendText,
    required this.onSendImages,
    required this.onSendEmoticon,
  });

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  bool _isEmoticonPickerOpen = false;
  bool _isPickingImage = false;
  final List<File> _selectedImages = [];
  List<CustomEmoticonModel> _matchedEmoticons = [];
  String _matchedKeyword = '';
  String _dismissedKeyword = '';
  double _keyboardHeight = 280;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    setState(() {});
    _checkKeywordMatching(text);
  }

  void _checkKeywordMatching(String text) {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      if (_matchedEmoticons.isNotEmpty) {
        setState(() {
          _matchedEmoticons = [];
          _matchedKeyword = '';
        });
      }
      return;
    }

    final words = trimmed.split(RegExp(r'\s+'));
    final lastWord = words.isNotEmpty ? words.last : '';

    if (lastWord.isEmpty || lastWord == _dismissedKeyword) {
      if (_matchedEmoticons.isNotEmpty) {
        setState(() {
          _matchedEmoticons = [];
          _matchedKeyword = '';
        });
      }
      return;
    }

    ref.read(customEmoticonRepositoryProvider).searchByKeyword(userId, lastWord).then((results) {
      if (!mounted) return;
      setState(() {
        _matchedEmoticons = results;
        _matchedKeyword = lastWord;
      });
    });
  }

  void _onDismissRecommendation() {
    setState(() {
      _dismissedKeyword = _matchedKeyword;
      _matchedEmoticons = [];
    });
  }

  void _onEmoticonSelectedFromBar(CustomEmoticonModel emoticon) {
    final file = File(emoticon.localImagePath);
    if (!file.existsSync()) return;

    widget.onSendEmoticon(file);

    final text = _controller.text.trim();
    if (text == _matchedKeyword) {
      _controller.clear();
    }

    setState(() {
      _matchedEmoticons = [];
      _matchedKeyword = '';
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();

    if (_selectedImages.isNotEmpty) {
      widget.onSendImages(List.from(_selectedImages));
      setState(() => _selectedImages.clear());
    }

    if (text.isNotEmpty) {
      widget.onSendText(text);
      _controller.clear();
    }

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

  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    FocusScope.of(context).unfocus();
    if (_isEmoticonPickerOpen) {
      setState(() => _isEmoticonPickerOpen = false);
    }

    final source = await showImageSourcePickerModal(context);
    if (source == null) return;

    setState(() => _isPickingImage = true);

    try {
      if (source == ImageSource.camera) {
        final pickedFile = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (pickedFile != null && mounted) {
          setState(() {
            if (_selectedImages.length < 10) {
              _selectedImages.add(File(pickedFile.path));
            }
          });
        }
      } else {
        // 앨범에서 여러 장 선택 (최대 10장)
        final pickedFiles = await _picker.pickMultiImage(
          imageQuality: 85,
        );
        if (pickedFiles.isNotEmpty && mounted) {
          setState(() {
            final remainingSlots = 10 - _selectedImages.length;
            if (remainingSlots > 0) {
              _selectedImages.addAll(
                pickedFiles.map((x) => File(x.path)).take(remainingSlots),
              );
            }
          });
        }
      }
    } catch (e, s) {
      AppLogger.e('Error picking chat images: $e', tag: 'CHAT', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진을 불러올 수 없습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasContentOrImage = _controller.text.trim().isNotEmpty || _selectedImages.isNotEmpty;
    final isDark = AppColors.isDark(context);
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    if (viewInsetsBottom > 0 && viewInsetsBottom != _keyboardHeight) {
      _keyboardHeight = viewInsetsBottom;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 이모티콘 추천 바 (키워드 매칭 시 표시)
        if (_matchedEmoticons.isNotEmpty)
          EmoticonRecommendBar(
            emoticons: _matchedEmoticons,
            onSelected: _onEmoticonSelectedFromBar,
            onDismiss: _onDismissRecommendation,
          ),

        // 2. 선택된 사진 썸네일 미리보기 플로팅 카드
        if (_selectedImages.isNotEmpty)
          Container(
            height: 74,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, index) {
                final file = _selectedImages[index];
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          file,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImages.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.x,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        // 3. All-in-One Floating Pill Capsule Bar (댓글창과 100% 동일한 외형 및 크기)
        SafeArea(
          top: false,
          bottom: !_isEmoticonPickerOpen && viewInsetsBottom == 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
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
                  // 1) Photo Attachment Button
                  IconButton(
                    onPressed: _isPickingImage ? null : _pickImage,
                    icon: _isPickingImage
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                          )
                        : Icon(
                            LucideIcons.image_plus,
                            color: AppColors.textSecondaryOf(context),
                            size: 22,
                          ),
                    tooltip: '사진 첨부',
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                  ),
                  const SizedBox(width: 4),

                  // 2) Seamless Borderless TextField
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
                      onChanged: _onTextChanged,
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요...',
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

                  // 3) Right Action Button ([😀] ↔ [✈️])
                  if (hasContentOrImage)
                    IconButton(
                      onPressed: _handleSend,
                      icon: const Icon(
                        LucideIcons.send,
                        color: AppColors.primaryDark,
                        size: 20,
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
                        LucideIcons.face_slightly_smiling,
                        color: _isEmoticonPickerOpen
                            ? AppColors.primary
                            : AppColors.textSecondaryOf(context),
                        size: 22,
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
        ),

        // 4. 내 사진 이모티콘 피커 패널
        if (_isEmoticonPickerOpen)
          EmoticonPickerPanel(
            height: _keyboardHeight,
            onSelected: (emoticon) {
              final file = File(emoticon.localImagePath);
              if (file.existsSync()) {
                widget.onSendEmoticon(file);
              }
            },
            onOpenManageScreen: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomEmoticonManageScreen()),
              );
            },
          ),
      ],
    );
  }
}
