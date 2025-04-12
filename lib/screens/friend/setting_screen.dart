import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/auth_controller.dart';
import 'package:manito/controllers/friends_controller.dart';

class SettingScreen extends StatelessWidget {
  SettingScreen({super.key});
  final _authController = Get.put(AuthController());
  final FriendsController _friendsController = Get.find<FriendsController>();

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
        title: Text(
          '설정',
          style: Get.textTheme.headlineLarge,
        ),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            Container(
              height: 0.15 * width,
              alignment: Alignment.center,
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0.05 * width),
                leading: Icon(Icons.refresh),
                title: Text('친구목록 새로고침'),
                onTap: () {
                  _friendsController.isLoading.value = true;
                  _friendsController.getProfile();
                  _friendsController.fetchFriendList();
                  _friendsController.isLoading.value = false;
                },
              ),
            ),
            // 로그아웃
            Container(
              height: 0.15 * width,
              alignment: Alignment.center,
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0.05 * width),
                leading: Icon(Icons.logout_outlined),
                title: Text('로그아웃'),
                onTap: _authController.logout,
              ),
            ),
          ],
        ),
        // Column(
        //   children: [
        //     ElevatedButton(
        //       onPressed: _authController.logout,
        //       child: Text('로그아웃'),
        //     ),
        //     ElevatedButton(
        //       onPressed: () {
        //         _friendsController.isLoading.value = true;
        //         _friendsController.getProfile();
        //         _friendsController.fetchFriendList();
        //         _friendsController.isLoading.value = false;
        //       },
        //       child: Text('친구 목록 새로고침'),
        //     ),
        //   ],
        // ),
      ),
    );
  }
}
