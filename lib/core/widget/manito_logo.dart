import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ManitoLogo extends StatelessWidget {
  final double fontSize;
  final Color? color;
  final bool isItalic;
  final bool showBadge;

  const ManitoLogo({
    super.key,
    this.fontSize = 24,
    this.color,
    this.isItalic = true,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? AppColors.textPrimary;

    Widget textWidget = Text(
      'manito',
      style: TextStyle(
        fontFamily: 'CookieRun',
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        color: logoColor,
        letterSpacing: -0.5,
      ),
    );

    if (!showBadge) return textWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        textWidget,
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'SECRET',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
