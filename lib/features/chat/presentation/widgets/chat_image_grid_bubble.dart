import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:manito/core/theme/app_colors.dart';
import '../screens/chat_gallery_screen.dart';

class ChatImageGridBubble extends StatelessWidget {
  final List<String> imageUrls;
  final bool isMe;

  const ChatImageGridBubble({
    super.key,
    required this.imageUrls,
    required this.isMe,
  });

  void _openGallery(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatGalleryScreen(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    final count = imageUrls.length;

    // 1. 사진 1장
    if (count == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onTap: () => _openGallery(context, 0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 240, maxHeight: 300),
            color: AppColors.surfaceLowOf(context),
            child: CachedNetworkImage(
              imageUrl: imageUrls[0],
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 200,
                height: 200,
                color: AppColors.surfaceLowOf(context),
                child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              errorWidget: (_, __, ___) => const Icon(LucideIcons.image_off, size: 40),
            ),
          ),
        ),
      );
    }

    // 2. 사진 2장
    if (count == 2) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 240),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GestureDetector(
                    onTap: () => _openGallery(context, 0),
                    child: CachedNetworkImage(
                      imageUrl: imageUrls[0],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GestureDetector(
                    onTap: () => _openGallery(context, 1),
                    child: CachedNetworkImage(
                      imageUrl: imageUrls[1],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. 사진 3~4장 (2x2 Grid)
    final displayCount = count > 4 ? 4 : count;
    final gridItems = imageUrls.take(4).toList();

    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
            childAspectRatio: 1,
          ),
          itemCount: displayCount,
          itemBuilder: (ctx, index) {
            final isLastOverlay = index == 3 && count > 4;
            final remainingCount = count - 4;

            return Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () => _openGallery(context, index),
                  child: CachedNetworkImage(
                    imageUrl: gridItems[index],
                    fit: BoxFit.cover,
                  ),
                ),
                if (isLastOverlay)
                  GestureDetector(
                    onTap: () => _openGallery(context, index),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      alignment: Alignment.center,
                      child: Text(
                        '+$remainingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
