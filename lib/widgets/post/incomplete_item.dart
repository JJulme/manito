import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class IncompleteItem extends StatelessWidget {
  final double width;
  final String creatorId;
  final creatorProfile;

  const IncompleteItem({
    super.key,
    required this.width,
    required this.creatorId,
    required this.creatorProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 0.03 * width,
        vertical: 0.02 * width,
      ),
      margin: EdgeInsets.only(
        left: 0.03 * width,
        right: 0.03 * width,
        bottom: 0.03 * width,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(0.02 * width),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          profileImageOrDefault(creatorProfile.profileImageUrl, 0.14 * width),
          SizedBox(width: 0.03 * width),
          Expanded(
            child: Text(
              '${creatorProfile.nickname} (이)가 마니또 추측중 입니다.',
              style: Get.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
