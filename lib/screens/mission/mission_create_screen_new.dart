import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MissionCreateScreenNew extends StatefulWidget {
  const MissionCreateScreenNew({super.key});

  @override
  State<MissionCreateScreenNew> createState() => _MissionCreateScreenNewState();
}

class _MissionCreateScreenNewState extends State<MissionCreateScreenNew> {
  // 토글버튼
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return Scaffold(appBar: _buildAppBar(width), body: _buildBody(width));
  }

  // 앱바
  AppBar _buildAppBar(double screenWidth) {
    return AppBar(
      centerTitle: false,
      titleSpacing: screenWidth * 0.02,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: Get.back,
      ),
      title:
          Text(
            "mission_create_screen.title",
            style: Get.textTheme.headlineMedium,
          ).tr(),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: screenWidth * 0.02),
          child: TextButton(
            onPressed: () {},
            child:
                Text(
                  "mission_create_screen.done",
                  style: Get.textTheme.bodyMedium,
                ).tr(),
          ),
        ),
      ],
    );
  }

  // 바디
  Widget _buildBody(double screenWidth) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: "타입", width: screenWidth),
            _PeriodToggleButtons(
              selectedIndex: _selectedIndex,
              onPeriodChanged:
                  (index) => setState(() => _selectedIndex = index),
              screenWidth: screenWidth,
            ),
            Divider(),
          ],
        ),
      ),
    );
  }
}

// 타이틀 위젯
class _SectionTitle extends StatelessWidget {
  final String title;
  final double width;
  const _SectionTitle({required this.title, required this.width});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(width * 0.05),
      child: Text(title, style: Get.textTheme.titleLarge),
    );
  }
}

// 토글 버튼
class _PeriodToggleButtons extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onPeriodChanged;
  final double screenWidth;

  const _PeriodToggleButtons({
    required this.selectedIndex,
    required this.onPeriodChanged,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: ToggleButtons(
        fillColor: Colors.yellowAccent[300],
        selectedColor: Colors.yellowAccent[900],
        selectedBorderColor: Colors.yellowAccent[900],
        borderRadius: BorderRadius.circular(screenWidth * 0.01),
        constraints: BoxConstraints(
          minHeight: screenWidth * 0.25,
          minWidth: (screenWidth - screenWidth * 0.1) / 3,
        ),
        isSelected: [
          selectedIndex == 0,
          selectedIndex == 1,
          selectedIndex == 2,
        ],
        onPressed: onPeriodChanged,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sunny),
              Text("일상", textAlign: TextAlign.center),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_rounded),
              Text("학교", textAlign: TextAlign.center),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.work),
              Text("직장", textAlign: TextAlign.center),
            ],
          ),
        ],
      ),
    );
  }
}
