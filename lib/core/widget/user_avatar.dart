import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manito/core/theme/app_colors.dart';

/// App-wide standard UserAvatar component supporting dynamic light/dark theming,
/// network caching, local asset images, and fallback icons.
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double borderWidth;
  final Color? borderColor;
  final Color? backgroundColor;
  final bool showShadow;
  final IconData fallbackIcon;
  final Color? fallbackIconColor;
  final double? fallbackIconSize;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.size = 44,
    this.borderWidth = 1.0,
    this.borderColor,
    this.backgroundColor,
    this.showShadow = false,
    this.fallbackIcon = Icons.person_rounded,
    this.fallbackIconColor,
    this.fallbackIconSize,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? AppColors.borderOf(context);
    final effectiveBgColor = backgroundColor ?? AppColors.surfaceLowOf(context);
    final effectiveIconColor = fallbackIconColor ?? AppColors.textDisabledOf(context);
    final effectiveIconSize = fallbackIconSize ?? (size * 0.55);

    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    Widget imageContent;
    if (!hasImage) {
      imageContent = Icon(
        fallbackIcon,
        size: effectiveIconSize,
        color: effectiveIconColor,
      );
    } else if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
      imageContent = CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        placeholder: (_, __) => Container(color: AppColors.surfaceOf(context)),
        errorWidget: (_, __, ___) => Icon(
          fallbackIcon,
          size: effectiveIconSize,
          color: effectiveIconColor,
        ),
      );
    } else {
      imageContent = Image.asset(
        imageUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => Icon(
          fallbackIcon,
          size: effectiveIconSize,
          color: effectiveIconColor,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveBgColor,
        border: borderWidth > 0
            ? Border.all(color: effectiveBorderColor, width: borderWidth)
            : null,
        boxShadow: showShadow ? AppColors.cardShadowOf(context) : null,
      ),
      child: ClipOval(
        child: imageContent,
      ),
    );
  }
}
