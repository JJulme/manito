import 'package:flutter/material.dart';
import 'package:manito/main.dart';

class CustomPopupMenuItem extends PopupMenuItem<String> {
  CustomPopupMenuItem({
    super.key,
    required Widget icon,
    required String text,
    required String value,
    super.onTap,
  }) : super(
         value: value,
         //  padding: EdgeInsets.zero,
         child: Row(
           mainAxisSize: MainAxisSize.min,
           mainAxisAlignment: MainAxisAlignment.start,
           children: [icon, SizedBox(width: width * 0.02), Text(text)],
         ),
       );
}
