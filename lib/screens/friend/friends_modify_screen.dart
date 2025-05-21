import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FriendsModifyScreen extends StatelessWidget {
  const FriendsModifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0.02 * width,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
        title: Text('친구 정보'),
      ),
      body: SafeArea(child: Center()),
    );
  }
}

class FriendsModifyController extends GetxController {}
