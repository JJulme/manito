import 'package:flutter/material.dart';
import 'package:manito/core/widget/profile_image_view.dart';
import 'package:manito/main.dart';

class ProfileItem extends StatelessWidget {
  final String profileImageUrl;
  final String name;
  final String statusMessage;
  const ProfileItem({
    super.key,
    required this.profileImageUrl,
    required this.name,
    required this.statusMessage,
  });

  static const double _horizontalPadding = 0.03;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * _horizontalPadding),
      child: Row(
        children: [
          // 프로필 이미지
          ProfileImageView(
            size: width * 0.27,
            profileImageUrl: profileImageUrl,
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // 이름
                    Text(
                      name,
                      style: TextTheme.of(context).titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(width: width * 0.09),
                  ],
                ),
                SizedBox(height: width * 0.03),
                // 상태 메시지
                Container(
                  width: double.infinity,
                  height: width * 0.15,
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.03,
                    vertical: width * 0.015,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(width * 0.01),
                  ),
                  child: Text(
                    statusMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextTheme.of(context).bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
