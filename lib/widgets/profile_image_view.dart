import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manito/core/custom_icons.dart';

class ProfileImageView extends StatelessWidget {
  final double size;
  final String profileImageUrl;
  const ProfileImageView({
    super.key,
    required this.size,
    required this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return profileImageUrl.isEmpty ? profileDefault() : profileUser();
  }

  // 프로필 이미지 없을때 기본 프로필
  Container profileDefault() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: Icon(CustomIcons.user, size: size * 0.35, color: Colors.grey[500]),
    );
  }

  Widget profileUser() {
    return CachedNetworkImage(
      imageUrl: profileImageUrl,
      imageBuilder:
          (context, imageProvider) => SizedBox(
            width: size,
            height: size,
            child: CircleAvatar(backgroundImage: imageProvider),
          ),
      placeholder: (context, url) => profileDefault(),
      errorWidget: (context, url, error) => profileDefault(),
    );
  }
}
