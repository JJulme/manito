import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:manito/core/theme/app_colors.dart';

class ChatEmoticonBubble extends StatelessWidget {
  final String imageUrl;
  final double size;

  const ChatEmoticonBubble({
    super.key,
    required this.imageUrl,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        placeholder: (_, __) => Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLowOf(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(LucideIcons.image_off, size: 36, color: AppColors.textDisabled),
        ),
      ),
    );
  }
}
