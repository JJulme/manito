import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/friends_controller.dart';

class FriendsModifyScreen extends StatefulWidget {
  const FriendsModifyScreen({super.key});

  @override
  State<FriendsModifyScreen> createState() => _FriendsModifyScreenState();
}

class _FriendsModifyScreenState extends State<FriendsModifyScreen> {
  late final FriendsModifyController _controller;

  /// 이름 텍스트 필드 폼키
  final _formKey = GlobalKey<FormState>();
  // Constants
  static const int _maxNameLength = 10;
  static const double _horizontalPadding = 0.05;
  static const double _verticalSpacing = 0.02;
  static const double _iconSize = 0.08;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(FriendsModifyController());
  }

  /// 이름 입력 검증 함수
  String? _validateNickname(String? value) {
    // 값이 비어있는지 확인
    if (value == null || value.trim().isEmpty) {
      return context.tr("friends_modify_screen.validator");
    }

    return null;
  }

  /// 프로필 수정하기
  void _updateProfile() async {
    if (_controller.isLoading.value) return;
    if (_formKey.currentState?.validate() == true) {
      await _controller.updateFriendName();
    }
  }

  // 본체
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: _buildAppBar(width),
        body: SafeArea(child: _buildBody(width)),
      ),
    );
  }

  // 앱바
  AppBar _buildAppBar(double screenWidth) {
    return AppBar(
      centerTitle: false,
      titleSpacing: screenWidth * _verticalSpacing,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Get.back(),
      ),
      title:
          Text(
            "friends_modify_screen.title",
            style: Get.textTheme.titleMedium,
          ).tr(),
      actions: [_buildUpdateBtn()],
    );
  }

  // 프로필 수정 버튼
  IconButton _buildUpdateBtn() {
    return IconButton(
      icon:
          _controller.isUpdate.value
              ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              )
              : Icon(
                Icons.check,
                color: Colors.green,
                size: Get.width * _iconSize,
              ),
      onPressed: _updateProfile,
    );
  }

  // 바디
  Widget _buildBody(double screenWidth) {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return _buildContent(screenWidth);
    });
  }

  // 바디 컬럼
  Widget _buildContent(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: _verticalSpacing * screenWidth),
        _buildNameInputSection(screenWidth),
        _buildCurrentNameDisplay(screenWidth),
      ],
    );
  }

  // 친구 이름 수정 텍스트 폼필드
  Widget _buildNameInputSection(double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _horizontalPadding * screenWidth,
      ),
      child: Form(
        key: _formKey,
        child: TextFormField(
          maxLength: _maxNameLength,
          validator: _validateNickname,
          controller: _controller.friendNameController,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\n]'))],
          decoration: InputDecoration(
            labelText: context.tr("friends_modify_screen.name"),
          ),
        ),
      ),
    );
  }

  // 친구가 직접 설정한 이름 보여주는 텍스트
  Widget _buildCurrentNameDisplay(double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _horizontalPadding * screenWidth,
      ),
      child: Text(
        '${context.tr("friends_modify_screen.friend_set_name")} : ${_controller.nickname}',
        style: Get.textTheme.bodySmall,
      ),
    );
  }
}
