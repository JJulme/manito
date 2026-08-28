import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/image/image_source_picker_modal.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/models/models.dart';

class BlockEditorView extends StatefulWidget {
  final List<RecordBlock> initialBlocks;
  final Function(List<RecordBlock>) onBlocksChanged;
  final Future<String> Function(File)? onUploadImage;
  final String? hintText;
  final bool hasError;
  final String? errorMessage;

  const BlockEditorView({
    super.key,
    required this.initialBlocks,
    required this.onBlocksChanged,
    this.onUploadImage,
    this.hintText,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  State<BlockEditorView> createState() => _BlockEditorViewState();
}

class _BlockEditorViewState extends State<BlockEditorView> {
  late List<RecordBlock> _blocks;
  final Map<int, TextEditingController> _controllers = {};
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initBlocks(widget.initialBlocks);
  }

  @override
  void didUpdateWidget(covariant BlockEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialBlocks != oldWidget.initialBlocks) {
      if (widget.initialBlocks.isNotEmpty && _blocks.length <= 1 && (_blocks.isEmpty || _blocks.first.value.isEmpty)) {
        _initBlocks(widget.initialBlocks);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  void _initBlocks(List<RecordBlock> initial) {
    if (initial.isNotEmpty) {
      _blocks = List.from(initial);
    } else {
      _blocks = [const RecordBlock(type: BlockType.text, value: '')];
    }
    _sanitizeBlocks();
    _syncControllers();
  }

  void _syncControllers() {
    // 기존 컨트롤러 해제
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();

    for (int i = 0; i < _blocks.length; i++) {
      if (_blocks[i].type == BlockType.text) {
        _controllers[i] = TextEditingController(text: _blocks[i].value);
      }
    }
  }

  void _notifyChange() {
    // 컨트롤러의 최신 텍스트 반영 후 전달
    for (int i = 0; i < _blocks.length; i++) {
      if (_controllers.containsKey(i)) {
        _blocks[i] = RecordBlock(type: BlockType.text, value: _controllers[i]!.text);
      }
    }
    widget.onBlocksChanged(List.from(_blocks));
  }

  int get _imageCount => _blocks.where((b) => b.type == BlockType.image).length;

  /// 인접한 중복 빈 텍스트 블록 정리 및 최소 1개 텍스트 블록 보장
  void _sanitizeBlocks() {
    if (_blocks.isEmpty) {
      _blocks = [const RecordBlock(type: BlockType.text, value: '')];
      return;
    }

    final sanitized = <RecordBlock>[];
    for (int i = 0; i < _blocks.length; i++) {
      final current = _blocks[i];
      if (current.type == BlockType.text && current.value.trim().isEmpty) {
        if (sanitized.isNotEmpty &&
            sanitized.last.type == BlockType.text &&
            sanitized.last.value.trim().isEmpty) {
          continue;
        }
      }
      sanitized.add(current);
    }

    if (!sanitized.any((b) => b.type == BlockType.text)) {
      sanitized.add(const RecordBlock(type: BlockType.text, value: ''));
    }

    _blocks = sanitized;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_imageCount >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진은 최대 10장까지 첨부할 수 있습니다.')),
      );
      return;
    }

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    String imagePath;
    if (widget.onUploadImage != null) {
      setState(() => _isUploading = true);
      try {
        imagePath = await widget.onUploadImage!(File(picked.path));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('이미지 업로드 실패: $e')),
          );
        }
        return;
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    } else {
      imagePath = picked.path;
    }

    setState(() {
      // 텍스트 컨트롤러 현재 내용 동기화
      for (int i = 0; i < _blocks.length; i++) {
        if (_controllers.containsKey(i)) {
          _blocks[i] = RecordBlock(type: BlockType.text, value: _controllers[i]!.text);
        }
      }

      // 1. 단일 빈 텍스트 블록만 있었던 경우: 사진을 상단에 넣고 빈 텍스트를 하단에 배치
      if (_blocks.length == 1 &&
          _blocks.first.type == BlockType.text &&
          _blocks.first.value.trim().isEmpty) {
        _blocks = [
          RecordBlock(type: BlockType.image, value: imagePath),
          const RecordBlock(type: BlockType.text, value: ''),
        ];
      } else {
        // 2. 마지막 블록이 빈 텍스트 블록이면 그 바로 앞에 사진 삽입
        if (_blocks.isNotEmpty &&
            _blocks.last.type == BlockType.text &&
            _blocks.last.value.trim().isEmpty) {
          _blocks.insert(_blocks.length - 1, RecordBlock(type: BlockType.image, value: imagePath));
        } else {
          // 3. 마지막 블록에 텍스트가 이미 작성되어 있으면 사진 추가 및 새 텍스트 블록 추가
          _blocks.add(RecordBlock(type: BlockType.image, value: imagePath));
          _blocks.add(const RecordBlock(type: BlockType.text, value: ''));
        }
      }
      _sanitizeBlocks();
      _syncControllers();
    });
    _notifyChange();
  }

  Future<void> _showImageSourcePicker(BuildContext context) async {
    final source = await showImageSourcePickerModal(context, title: '인증 사진 첨부');
    if (source != null) {
      _pickImage(source);
    }
  }

  void _removeBlock(int index) {
    setState(() {
      for (int i = 0; i < _blocks.length; i++) {
        if (_controllers.containsKey(i)) {
          _blocks[i] = RecordBlock(type: BlockType.text, value: _controllers[i]!.text);
        }
      }
      _blocks.removeAt(index);
      _sanitizeBlocks();
      _syncControllers();
    });
    _notifyChange();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Editor Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderOf(context)),
            boxShadow: AppColors.cardShadowOf(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Photo Dropzone Placeholder (사진 미등록 시 시각적 필수 안내 카드)
              if (_imageCount == 0) ...[
                InkWell(
                  onTap: _isUploading ? null : () => _showImageSourcePicker(context),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: widget.hasError
                          ? AppColors.statusRed.withValues(alpha: 0.05)
                          : AppColors.surfaceLowOf(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: widget.hasError
                            ? AppColors.statusRed
                            : AppColors.primary.withValues(alpha: 0.6),
                        width: widget.hasError ? 1.8 : 1.2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceOf(context),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_a_photo_outlined,
                            color: widget.hasError ? AppColors.statusRed : AppColors.primaryDark,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '인증 사진을 첨부해 주세요',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: widget.hasError ? AppColors.statusRed : AppColors.textPrimaryOf(context),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '(필수)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.statusRed,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.hasError
                              ? (widget.errorMessage ?? '⚠️ 저장하려면 사진을 1장 이상 등록해야 합니다')
                              : '카메라 촬영 또는 갤러리에서 선택할 수 있습니다',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: widget.hasError ? FontWeight.w600 : FontWeight.normal,
                            color: widget.hasError ? AppColors.statusRed : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 2. Blocks List (Images & Text fields)
              ...List.generate(_blocks.length, (idx) {
                final block = _blocks[idx];

                if (block.type == BlockType.image) {
                  return Padding(
                    key: ValueKey('img_${idx}_${block.value}'),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: block.value.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: block.value,
                                  fit: BoxFit.fitWidth,
                                  width: double.infinity,
                                  placeholder: (_, __) => Container(
                                    height: 160,
                                    color: AppColors.surface,
                                    alignment: Alignment.center,
                                    child: const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    height: 100,
                                    color: AppColors.surface,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
                                  ),
                                )
                              : Image.file(
                                  File(block.value),
                                  fit: BoxFit.fitWidth,
                                  width: double.infinity,
                                ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () => _removeBlock(idx),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Padding(
                    key: ValueKey('txt_$idx'),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextFormField(
                      controller: _controllers[idx],
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: widget.hintText ?? '미션을 어떻게 했는지 작성해 주세요.',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      style: AppTypography.bodyMd,
                      onChanged: (val) {
                        _blocks[idx] = RecordBlock(type: BlockType.text, value: val);
                        widget.onBlocksChanged(List.from(_blocks));
                      },
                    ),
                  );
                }
              }),

              if (_isUploading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Attachment Action Toolbar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.camera_alt_outlined, color: AppColors.textPrimary),
                        tooltip: '카메라 촬영',
                        onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo_library_outlined, color: AppColors.textPrimary),
                        tooltip: '갤러리 사진 첨부',
                        onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                      ),
                    ],
                  ),
                  Text(
                    _imageCount > 0 ? '✅ 사진 $_imageCount/10장' : '사진 0/10장 (필수)*',
                    style: AppTypography.labelSm.copyWith(
                      color: _imageCount > 0 ? AppColors.statusGreen : AppColors.statusRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
