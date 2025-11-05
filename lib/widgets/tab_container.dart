import 'package:flutter/material.dart';
import 'package:manito/main.dart';

class TabContainer extends StatelessWidget {
  final Widget child;
  const TabContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width - (width * 0.06),
      height: width * 0.2,
      padding: EdgeInsets.symmetric(
        vertical: width * 0.03,
        horizontal: width * 0.03,
      ),
      margin: EdgeInsets.only(
        left: width * 0.03,
        right: width * 0.03,
        bottom: width * 0.03,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(width * 0.02),
      ),
      child: child,
    );
  }
}
