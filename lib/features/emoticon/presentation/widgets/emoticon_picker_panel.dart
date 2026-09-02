import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/features/emoticon/data/models/custom_emoticon_model.dart';
import 'package:manito/features/emoticon/presentation/emoticon_provider.dart';

/// 댓글창 하단 키보드 영역에 표시되는 이모티콘 선택 패널 (가로 스크롤 태그 바 + 설정 아이콘 + 4열 그리드)
class EmoticonPickerPanel extends ConsumerStatefulWidget {
  final double height;
  final ValueChanged<CustomEmoticonModel> onSelected;
  final VoidCallback onOpenManageScreen;

  const EmoticonPickerPanel({
    super.key,
    required this.height,
    required this.onSelected,
    required this.onOpenManageScreen,
  });

  @override
  ConsumerState<EmoticonPickerPanel> createState() => _EmoticonPickerPanelState();
}

class _EmoticonPickerPanelState extends ConsumerState<EmoticonPickerPanel> {
  String? _selectedTag; // null이면 '전체'

  @override
  Widget build(BuildContext context) {
    final emoticonsAsync = ref.watch(userEmoticonsProvider);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
        border: Border(
          top: BorderSide(color: AppColors.borderOf(context), width: 0.8),
        ),
      ),
      child: Column(
        children: [
          // 1. 상단 툴바 (가로 스크롤 태그 버튼 목록 + 설정 아이콘)
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceLowOf(context),
              border: Border(
                bottom: BorderSide(color: AppColors.borderOf(context), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                // 가로 스크롤 태그 칩 바
                Expanded(
                  child: emoticonsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (emoticons) {
                      // 전체 고유 태그 목록 추출
                      final allTags = <String>{};
                      for (final e in emoticons) {
                        for (final t in e.tags) {
                          if (t.trim().isNotEmpty) allTags.add(t.trim());
                        }
                      }
                      final tagList = allTags.toList();

                      // 선택된 태그가 목록에 없으면 '전체'로 리셋
                      if (_selectedTag != null && !allTags.contains(_selectedTag)) {
                        _selectedTag = null;
                      }

                      final totalChips = 1 + tagList.length; // '전체' + 태그들

                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
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
                      );
                    },
                  ),
                ),

                // 구분선
                Container(
                  width: 1,
                  height: 20,
                  color: AppColors.borderOf(context),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),

                // 환경설정 아이콘 버튼 (텍스트 제거)
                IconButton(
                  onPressed: widget.onOpenManageScreen,
                  icon: Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: AppColors.textSecondaryOf(context),
                  ),
                  tooltip: '이모티콘 관리',
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),

          // 2. 이모티콘 그리드 본문
          Expanded(
            child: SafeArea(
              top: false,
              child: emoticonsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                error: (err, _) => Center(
                  child: Text('이모티콘 로드 실패: $err', style: AppTypography.bodySm),
                ),
                data: (emoticons) {
                  if (emoticons.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_emotions_outlined,
                            size: 40,
                            color: AppColors.textDisabledOf(context),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '아직 등록된 이모티콘이 없어요.',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: widget.onOpenManageScreen,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('사진 추가하러 가기'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              textStyle: AppTypography.labelMd,
                            ),
                          ),
                        ],
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: displayList.length,
                    itemBuilder: (ctx, idx) {
                      final emoticon = displayList[idx];
                      final file = File(emoticon.localImagePath);

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onSelected(emoticon);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLowOf(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.borderOf(context).withValues(alpha: 0.6),
                              width: 0.8,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: file.existsSync()
                                ? Image.file(
                                    file,
                                    fit: BoxFit.cover,
                                    cacheWidth: 200,
                                  )
                                : Container(
                                    color: AppColors.surfaceLowOf(context),
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 20,
                                      color: AppColors.textDisabledOf(context),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
