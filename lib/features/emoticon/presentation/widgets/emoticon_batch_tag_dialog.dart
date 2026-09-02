import 'package:flutter/material.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';

/// 복수 사진 일괄 등록 시 공통 태그를 입력받는 다이얼로그
Future<List<String>?> showEmoticonBatchTagDialog(BuildContext context) async {
  return showDialog<List<String>>(
    context: context,
    builder: (ctx) => const _EmoticonBatchTagDialog(),
  );
}

class _EmoticonBatchTagDialog extends StatefulWidget {
  const _EmoticonBatchTagDialog();

  @override
  State<_EmoticonBatchTagDialog> createState() => _EmoticonBatchTagDialogState();
}

class _EmoticonBatchTagDialogState extends State<_EmoticonBatchTagDialog> {
  final _controller = TextEditingController();
  final List<String> _tags = [];

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
      title: const Text('태그 입력'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '선택한 사진들에 공통으로 적용할 태그를 입력해 주세요.',
              style: AppTypography.bodySm.copyWith(color: AppColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: 16),

            // 추가된 태그 칩 목록
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
                    deleteIcon: const Icon(Icons.close_rounded, size: 16),
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
                      hintText: '태그 입력 (예: ㅋㅋ, 웃김)',
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
                  icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                  tooltip: '태그 추가',
                ),
              ],
            ),

            if (_tags.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '최소 1개 이상의 태그를 입력해 주세요.',
                style: AppTypography.bodySm.copyWith(color: AppColors.textDisabledOf(context)),
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
          child: const Text('등록'),
        ),
      ],
    );
  }
}
