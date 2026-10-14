import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/features/emoticon/presentation/emoticon_provider.dart';
import 'package:manito/features/emoticon/presentation/widgets/emoticon_batch_tag_dialog.dart';
import 'package:manito/features/emoticon/presentation/widgets/emoticon_tag_edit_dialog.dart';

/// 나만의 사진 이모티콘 관리 화면
class CustomEmoticonManageScreen extends ConsumerStatefulWidget {
  const CustomEmoticonManageScreen({super.key});

  @override
  ConsumerState<CustomEmoticonManageScreen> createState() => _CustomEmoticonManageScreenState();
}

class _CustomEmoticonManageScreenState extends ConsumerState<CustomEmoticonManageScreen> {
  bool _isAdding = false;
  String? _selectedTag; // null이면 '전체'

  Future<void> _pickAndAddEmoticons() async {
    if (_isAdding) return;

    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 90,
        maxWidth: 600,
      );

      if (pickedFiles.isEmpty) return;

      if (!mounted) return;

      // 태그 입력 다이얼로그 표시
      final tags = await showEmoticonBatchTagDialog(context);
      if (tags == null || tags.isEmpty) return;

      setState(() => _isAdding = true);

      final files = pickedFiles.map((xf) => File(xf.path)).toList();
      await ref.read(emoticonServiceProvider).addMultipleEmoticons(
        originalFiles: files,
        tags: tags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${files.length}개의 이모티콘이 등록되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이모티콘 등록에 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _editTags(String emoticonId, List<String> currentTags) async {
    final result = await showEmoticonTagEditDialog(context, currentTags);
    if (result == null) return;
    await ref.read(emoticonServiceProvider).updateTags(emoticonId, result);
  }

  Future<void> _deleteEmoticon(String emoticonId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이모티콘 삭제'),
        content: const Text('이 이모티콘을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(emoticonServiceProvider).deleteEmoticon(emoticonId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이모티콘이 삭제되었습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final emoticonsAsync = ref.watch(userEmoticonsProvider);
    final statsAsync = ref.watch(emoticonUsageStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 사진 이모티콘'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 용량 및 개수 헤더
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowOf(context),
                border: Border(bottom: BorderSide(color: AppColors.borderOf(context))),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.image, size: 20, color: AppColors.textSecondaryOf(context)),
                  const SizedBox(width: 10),
                  Text(
                    stats.summary,
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '저장 용량',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 가로 스크롤 태그 단추 바
          emoticonsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (emoticons) {
              if (emoticons.isEmpty) return const SizedBox.shrink();

              // 전체 고유 태그 목록 추출
              final allTags = <String>{};
              for (final e in emoticons) {
                for (final t in e.tags) {
                  if (t.trim().isNotEmpty) allTags.add(t.trim());
                }
              }
              final tagList = allTags.toList();

              if (_selectedTag != null && !allTags.contains(_selectedTag)) {
                _selectedTag = null;
              }

              final totalChips = 1 + tagList.length; // '전체' + 태그들

              return Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowOf(context),
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderOf(context), width: 0.5),
                  ),
                ),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  itemCount: totalChips,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, idx) {
                    final isAll = idx == 0;
                    final tag = isAll ? null : tagList[idx - 1];
                    final isSelected = (isAll && _selectedTag == null) || (!isAll && _selectedTag == tag);
                    final label = isAll ? '전체' : '#$tag';

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedTag = tag;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceOf(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderOf(context),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (AppColors.isDark(context) ? Colors.black : Colors.black87)
                                : AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // 이모티콘 그리드
          Expanded(
            child: emoticonsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(child: Text('불러오기 실패: $err')),
              data: (emoticons) {
                if (emoticons.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.image_plus, size: 56, color: AppColors.textDisabledOf(context)),
                          const SizedBox(height: 12),
                          Text(
                            '아직 등록된 이모티콘이 없어요.\n사진을 추가하고 태그를 지정해 보세요!',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.textSecondaryOf(context),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isAdding ? null : _pickAndAddEmoticons,
                              icon: const Icon(LucideIcons.plus, size: 20),
                              label: const Text('사진 추가하기'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 선택된 태그로 필터링
                final displayList = _selectedTag == null
                    ? emoticons
                    : emoticons.where((e) => e.matchesKeyword(_selectedTag!)).toList();

                if (displayList.isEmpty) {
                  return Center(
                    child: Text(
                      '#$_selectedTag 태그의 이모티콘이 없습니다.',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: displayList.length,
                  itemBuilder: (ctx, idx) {
                    final emoticon = displayList[idx];
                    final file = File(emoticon.localImagePath);

                    return GestureDetector(
                      onTap: () => _editTags(emoticon.id, emoticon.tags),
                      onLongPress: () => _deleteEmoticon(emoticon.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLowOf(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderOf(context), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 1. 정사각형 썸네일 이미지
                              file.existsSync()
                                  ? Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: AppColors.surfaceLowOf(context),
                                      child: Center(
                                        child: Icon(
                                          LucideIcons.image_off,
                                          color: AppColors.textDisabledOf(context),
                                        ),
                                      ),
                                    ),

                              // 2. 하단 태그 오버레이 (부드러운 그라데이션)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.7),
                                      ],
                                    ),
                                  ),
                                  child: Text(
                                    emoticon.tags.join(', '),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black54,
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // 하단 추가 버튼
      floatingActionButton: emoticonsAsync.valueOrNull?.isNotEmpty == true
          ? FloatingActionButton(
              onPressed: _isAdding ? null : _pickAndAddEmoticons,
              backgroundColor: AppColors.primary,
              child: _isAdding
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.plus, color: Colors.white),
            )
          : null,
    );
  }
}
