// 숫자까지 표시하는 버전
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;

Widget customBadgeIconWithLabel(
  int badgeCount, {
  Widget? child,
  bool showLabel = false,
}) {
  if (badgeCount > 0) {
    return badges.Badge(
      badgeContent: showLabel ? Text('$badgeCount') : null,
      position: badges.BadgePosition.custom(top: 0, end: -4),
      child: child,
    );
  } else {
    return child ?? const SizedBox.shrink();
  }
}
