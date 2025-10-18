import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/custom_icons.dart';

class ManitoCount extends StatelessWidget {
  final String countManito;
  final String countMission;
  final double space;
  const ManitoCount({
    super.key,
    required this.countManito,
    required this.countMission,
    required this.space,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/icons/star.svg',
          width: width * 0.07,
          colorFilter: ColorFilter.mode(kYellow, BlendMode.srcIn),
        ),
        SizedBox(width: width * 0.02),
        Text(countMission, style: Get.textTheme.bodyMedium),
        SizedBox(width: space),
        Icon(CustomIcons.scroll, size: width * 0.06, color: kOrange),
        SizedBox(width: width * 0.03),
        Text(countManito, style: Get.textTheme.bodyMedium),
      ],
    );
  }
}
