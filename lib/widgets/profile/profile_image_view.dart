import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

Widget profileImageOrDefault(
  String? profileImageUrl,
  double size,
) {
  return profileImageUrl!.isNotEmpty
      ? Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: Image(
              image: CachedNetworkImageProvider(profileImageUrl),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: Icon(
                  Icons.error,
                  size: size * 0.5,
                  color: Colors.red,
                ),
              ),
            ),
          ))
      : Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_rounded,
            size: size * 0.5,
            color: Colors.grey[500],
          ),
        );
}
