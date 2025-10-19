import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manito/core/custom_icons.dart';

// Widget profileImageOrDefault(String? profileImageUrl, double size) {
//   return profileImageUrl!.isNotEmpty
//       ? Container(
//         height: size,
//         width: size,
//         decoration: const BoxDecoration(shape: BoxShape.circle),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(size / 2),
//           child: Image(
//             image: CachedNetworkImageProvider(profileImageUrl),
//             fit: BoxFit.cover,
//             errorBuilder:
//                 (context, error, stackTrace) => Container(
//                   color: Colors.grey[300],
//                   child: Icon(Icons.error, size: size * 0.5, color: Colors.red),
//                 ),
//           ),
//         ),
//       )
//       : Container(
//         height: size,
//         width: size,
//         decoration: BoxDecoration(
//           color: Colors.grey[300],
//           shape: BoxShape.circle,
//         ),
//         child: Icon(
//           CustomIcons.user,
//           size: size * 0.35,
//           color: Colors.grey[500],
//         ),
//       );
// }

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
