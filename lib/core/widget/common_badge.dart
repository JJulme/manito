import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;

class CommonBadge extends StatelessWidget {
  final int badgeCount;
  final Widget? child;
  final bool showLabel;
  final Color? badgeColor;

  const CommonBadge({
    super.key,
    required this.badgeCount,
    this.child,
    this.showLabel = false,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (badgeCount <= 0) {
      return child ?? const SizedBox.shrink();
    }

    return badges.Badge(
      // 배지 내부 텍스트 스타일 통일
      badgeContent:
          showLabel
              ? Text(
                badgeCount > 99 ? '99+' : '$badgeCount', // 99+ 처리 로직 추가
              )
              : null,
      // 배지 디자인 스타일 통일
      badgeStyle: badges.BadgeStyle(
        badgeColor: badgeColor ?? Theme.of(context).colorScheme.error,
        padding: showLabel ? const EdgeInsets.all(4) : const EdgeInsets.all(3),
      ),
      position: badges.BadgePosition.topEnd(top: -2, end: -4),
      child: child,
    );
  }
}
