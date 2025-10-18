import 'package:flutter/material.dart';

class MainAppbar extends StatelessWidget implements PreferredSizeWidget {
  final double width;
  final String text;
  final List<Widget>? actions;
  const MainAppbar({
    super.key,
    required this.width,
    required this.text,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      titleSpacing: width * 0.07,
      title: Text(text, style: Theme.of(context).textTheme.headlineLarge),
      actions: actions,
    );
  }
}
