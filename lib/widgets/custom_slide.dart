// 개별 FlipCard 위젯
import 'package:flutter/material.dart';

class CustomSlide extends StatefulWidget {
  final Widget mainWidget;
  final Widget subWidget;
  final VoidCallback? onTap;
  const CustomSlide({
    super.key,
    required this.mainWidget,
    required this.subWidget,
    this.onTap,
  });

  @override
  _CustomSlideState createState() => _CustomSlideState();
}

class _CustomSlideState extends State<CustomSlide> {
  bool isSubScreenVisible = false;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        widget.onTap?.call();
        setState(() {
          isSubScreenVisible = !isSubScreenVisible;
        });
      },
      child: Stack(
        children: [
          // 메인 화면
          widget.mainWidget,
          // 서브 화면 (애니메이션 적용)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            bottom: 0,
            right: isSubScreenVisible ? 0 : width,
            left: null,
            child: widget.subWidget,
          ),
        ],
      ),
    );
  }
}
