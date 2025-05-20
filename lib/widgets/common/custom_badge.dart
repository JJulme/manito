import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:badges/badges.dart' as badges;

Widget customBadgeIcon(RxInt badgeCount, {Widget? child}) {
  return Obx(() {
    if (badgeCount.value > 0) {
      return badges.Badge(
        position: badges.BadgePosition.custom(top: -1, end: -1),
        child: child,
      );
    } else {
      return child ?? const SizedBox.shrink();
    }
  });
}
