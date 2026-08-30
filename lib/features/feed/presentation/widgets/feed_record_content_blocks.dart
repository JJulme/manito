import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';

/// 피드 결과 레코드 블록(이미지 및 텍스트) 렌더러
class FeedRecordContentBlocks extends StatelessWidget {
  final List<RecordBlock> blocks;

  const FeedRecordContentBlocks({super.key, required this.blocks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks.map((block) {
        if (block.type == BlockType.image) {
          if (block.value.trim().isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: block.value.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: block.value,
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                      placeholder: (_, __) => Container(
                        height: 200,
                        color: AppColors.surfaceLowOf(context),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 100,
                        color: AppColors.surfaceLowOf(context),
                        alignment: Alignment.center,
                        child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondaryOf(context)),
                      ),
                    )
                  : Image.asset(
                      block.value,
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                    ),
            ),
          );
        } else {
          if (block.value.trim().isEmpty) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowOf(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              block.value,
              style: AppTypography.bodyMd.copyWith(height: 1.45, color: AppColors.textPrimaryOf(context)),
            ),
          );
        }
      }).toList(),
    );
  }
}
