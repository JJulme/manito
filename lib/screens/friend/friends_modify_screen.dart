import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/friends_controller.dart';

class FriendsModifyScreen extends StatelessWidget {
  FriendsModifyScreen({super.key});

  final FriendsModifyController _controller = Get.put(
    FriendsModifyController(),
  );

  /// 이름 텍스트 필드 폼키
  final _formKey = GlobalKey<FormState>();

  /// 이름 입력 검증 함수
  String? _validateNickname(String? value) {
    // 값이 비어있는지 확인
    if (value == null || value.isEmpty) {
      return '이름을 입력해주세요.';
    }
    final String trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return '이름을 입력해주세요.';
    }

    return null;
  }

  /// 프로필 수정하기
  void _updateProfile() async {
    if (_controller.isLoading.value) {
      return null;
    } else {
      if (_formKey.currentState!.validate()) {
        await _controller.updateFriendName();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 0.02 * width,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Get.back(),
          ),
          title: Text('친구 이름 수정'),
          actions: [_updateBtn(width)],
        ),
        body: SafeArea(
          child: Obx(() {
            if (_controller.isLoading.value) {
              return Center(child: CircularProgressIndicator());
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 0.02 * width),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
                  child: Form(
                    key: _formKey,
                    child: TextFormField(
                      maxLength: 10,
                      validator: _validateNickname,
                      controller: _controller.friendNameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'[\n]')),
                      ],
                      decoration: InputDecoration(labelText: '이름'),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
                  child: Text(
                    '친구가 설정한 이름 : ${_controller.nickname}',
                    style: Get.textTheme.bodySmall,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// 프로필 수정 버튼
  IconButton _updateBtn(double width) {
    return IconButton(
      icon:
          _controller.isUpdate.value
              ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              )
              : Icon(Icons.check, color: Colors.green, size: 0.08 * width),
      onPressed: _updateProfile,
    );
  }
}
