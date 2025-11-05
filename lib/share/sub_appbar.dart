import 'package:flutter/material.dart';
import 'package:manito/main.dart';

class SubAppbar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;

  const SubAppbar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      titleSpacing: width * 0.02,
      title: title,
      actions: actions,
    );
  }
}
