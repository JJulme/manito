import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MissionCreateScreenNew extends StatefulWidget {
  const MissionCreateScreenNew({super.key});

  @override
  State<MissionCreateScreenNew> createState() => _MissionCreateScreenNewState();
}

class _MissionCreateScreenNewState extends State<MissionCreateScreenNew> {
  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return Scaffold(appBar: _buildAppBar(width));
  }

  // 앱바
  AppBar _buildAppBar(double screenWidth) {
    return AppBar(
      centerTitle: false,
      titleSpacing: screenWidth * 0.02,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: Get.back,
      ),
      title:
          Text(
            "mission_create_screen.title",
            style: Get.textTheme.headlineMedium,
          ).tr(),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: screenWidth * 0.02),
          child: TextButton(
            onPressed: () {},
            child:
                Text(
                  "mission_create_screen.done",
                  style: Get.textTheme.bodyMedium,
                ).tr(),
          ),
        ),
      ],
    );
  }
}
