import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';

/// 개별 이모티콘의 태그를 추가/수정/삭제하는 다이얼로그
Future<List<String>?> showEmoticonTagEditDialog(
  BuildContext context,
  List<String> currentTags,
) async {
  return showDialog<List<String>>(
    context: context,
    builder: (ctx) => _EmoticonTagEditDialog(currentTags: currentTags),
  );
}

class _EmoticonTagEditDialog extends StatefulWidget {
  final List<String> currentTags;

  const _EmoticonTagEditDialog({required this.currentTags});

  @override
  State<_EmoticonTagEditDialog> createState() => _EmoticonTagEditDialogState();
}

class _EmoticonTagEditDialogState extends State<_EmoticonTagEditDialog> {
  late List<String> _tags;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List<String>.from(widget.currentTags);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _controller.text.trim();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() {
      _tags.add(tag);
      _controller.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('태그 관리'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 현재 태그 칩 목록
            if (_tags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    deleteIcon: const Icon(LucideIcons.x, size: 16),
                    onDeleted: () => _removeTag(tag),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 태그 입력 필드
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: '태그 입력 (예: ㅋㅋ)',
                      hintStyle: TextStyle(color: AppColors.textDisabledOf(context)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimaryOf(context)),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addTag,
                  icon: const Icon(LucideIcons.circle_plus, color: AppColors.primary),
                  tooltip: '태그 추가',
                ),
              ],
            ),

            if (_tags.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '최소 1개 이상의 태그가 필요합니다.',
                style: AppTypography.bodySm.copyWith(color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _tags.isEmpty ? null : () => Navigator.pop(context, _tags),
          child: const Text('저장'),
        ),
      ],
    );
  }
}
