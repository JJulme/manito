import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 카메라 / 갤러리 선택 공통 바텀시트 모달
Future<ImageSource?> showImageSourcePickerModal(
  BuildContext context, {
  String? title,
}) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderOf(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderOf(context)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.camera_alt_outlined, size: 32, color: AppColors.primaryDark),
                        const SizedBox(height: 8),
                        Text('카메라 촬영', style: AppTypography.titleSmall.copyWith(color: AppColors.textPrimaryOf(context))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderOf(context)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.photo_library_outlined, size: 32, color: AppColors.primaryDark),
                        const SizedBox(height: 8),
                        Text('앨범에서 선택', style: AppTypography.titleSmall.copyWith(color: AppColors.textPrimaryOf(context))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
