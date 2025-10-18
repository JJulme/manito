import 'package:flutter/material.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

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
    final double width = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * _horizontalPadding),
      child: Row(
        children: [
          // 프로필 이미지
          ProfileImageView(size: width * 0.3, profileImageUrl: profileImageUrl),
          SizedBox(width: width * 0.06),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(width: width * 0.09),
                    // ManitoCount(
                    //   countManito: '1',
                    //   countMission: '2',
                    //   space: width * 0.06,
                    // ),
                  ],
                ),
                SizedBox(height: width * 0.03),
                Text('특이사항', style: Theme.of(context).textTheme.bodySmall),
                Container(
                  width: double.infinity,
                  height: width * 0.15,
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.03,
                    vertical: width * 0.015,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(width * 0.01),
                  ),
                  child: Text(statusMessage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
