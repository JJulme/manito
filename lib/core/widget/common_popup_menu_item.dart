import 'package:flutter/material.dart';
import 'package:manito/main.dart';

class CommonPopupMenuItem extends PopupMenuItem<String> {
  CommonPopupMenuItem({
    super.key,
    required Widget icon,
    required String text,
    required String value,
    super.onTap,
  }) : super(
         value: value,
         child: Row(
           mainAxisSize: MainAxisSize.min,
           mainAxisAlignment: MainAxisAlignment.start,
           children: [icon, SizedBox(width: width * 0.02), Text(text)],
         ),
       );
}
