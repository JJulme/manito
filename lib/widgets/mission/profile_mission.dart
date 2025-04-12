import 'package:flutter/material.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

/// 프로필, 닉네임, 미션
class ProfileAndMission extends StatelessWidget {
  const ProfileAndMission({
    super.key,
    required this.creatorProfileUrl,
    required this.size,
    required this.creatorNickname,
    required this.content,
  });

  final String creatorProfileUrl;
  final double size;
  final String creatorNickname;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        profileImageOrDefault(
          creatorProfileUrl,
          size,
        ),
        SizedBox(width: 0.2 * size),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(creatorNickname, overflow: TextOverflow.ellipsis),
            Text(content, overflow: TextOverflow.ellipsis),
          ],
        ),
      ],
    );
  }
}
