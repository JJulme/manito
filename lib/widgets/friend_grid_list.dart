import 'package:flutter/material.dart';
import 'package:manito/widgets/profile_image_view.dart';
import 'package:manito/features/profiles/profile.dart';

class FriendGridList extends StatelessWidget {
  final List<FriendProfile> friends;

  const FriendGridList({super.key, required this.friends});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 6 / 7,
      ),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final profile = friends[index];
        return Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileImageView(
                size: width * 0.19,
                profileImageUrl: profile.profileImageUrl!,
              ),
              SizedBox(height: width * 0.02),
              Text(
                profile.displayName,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
