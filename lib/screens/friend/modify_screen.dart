import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';

class ModifyScreen extends StatefulWidget {
  const ModifyScreen({super.key});

  @override
  State<ModifyScreen> createState() => _ModifyScreenState();
}

class _ModifyScreenState extends State<ModifyScreen> {
  final ModifyController _controller = Get.put(ModifyController());

  /// 이름 텍스트 필드 폼키
  final _formKey = GlobalKey<FormState>();

  /// 이름 입력 검증 함수
  String? _validateNickname(String? value) {
    // 값이 비어있는지 확인
    if (value == null || value.isEmpty) {
      return context.tr("modify_screen.validator");
    }
    final String trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return context.tr("modify_screen.validator");
    }

    return null;
  }

  /// 프로필 수정하기
  void _updateProfile() async {
    if (_controller.isLoading.value) {
      return null;
    } else {
      if (_formKey.currentState!.validate()) {
        String result = await _controller.updateProfile();
        // 수정 성공 못하면 스넥바 출력
        if (result != 'modify_success') {
          if (!mounted) return;
          customSnackbar(
            title: context.tr("modify_screen.snack_title"),
            message: context.tr("modify_screen.$result"),
          );
        }
      }
    }
  }

  // 본체
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Obx(() {
        return Scaffold(
          appBar: _buildAppBar(),
          body: SafeArea(
            child: Stack(
              children: [
                _buildBody(),
                if (_controller.isLoading.value) _buildLoadingOverlay(),
              ],
            ),
          ),
        );
      }),
    );
  }

  // 앱바
  AppBar _buildAppBar() {
    return AppBar(
      centerTitle: false,
      title: Text('modify_screen.title').tr(),
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Get.back(),
      ),
      actions: [_buildUpdateBtn()],
    );
  }

  // 프로필 수정 버튼
  IconButton _buildUpdateBtn() {
    return IconButton(
      icon:
          _controller.isLoading.value
              ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              )
              : Icon(Icons.check, color: Colors.green, size: Get.width * 0.08),
      onPressed: _updateProfile,
    );
  }

  // 바디
  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ProfileImageWidget(
              controller: _controller,
              size: Get.width,
              onTap: _controller.pickImage,
              onDelete: _controller.deleteImage,
            ),
            SizedBox(height: Get.width * 0.06),
            _buildNameField(),
            SizedBox(height: Get.width * 0.06),
            _buildStatusField(),
          ],
        ),
      ),
    );
  }

  // 이름 입력창
  Widget _buildNameField() {
    return Form(
      key: _formKey,
      child: TextFormField(
        maxLength: 10,
        validator: _validateNickname,
        controller: _controller.nameController,
        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\n]'))],
        decoration: InputDecoration(
          labelText: context.tr('modify_screen.name'),
        ),
      ),
    );
  }

  // 상태메시지 입력창
  Widget _buildStatusField() {
    return TextFormField(
      minLines: 1,
      maxLines: 2,
      maxLength: 30,
      controller: _controller.statusController,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\n]'))],
      decoration: InputDecoration(
        labelText: context.tr("modify_screen.status_message"),
      ),
    );
  }

  // 로딩중 입력 방지
  Widget _buildLoadingOverlay() {
    return ModalBarrier(
      dismissible: false,
      color: Colors.black.withAlpha((0.5 * 255).round()),
    );
  }
}

// 프로필 이미지 설정
class ProfileImageWidget extends StatelessWidget {
  final ModifyController controller;
  final double size;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const ProfileImageWidget({
    super.key,
    required this.controller,
    required this.size,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Obx(() {
        return Stack(children: [_buildImageContainer(), _buildActionButton()]);
      }),
    );
  }

  // 이미지 컨테이너
  Widget _buildImageContainer() {
    final selectedImage = controller.selectedImage.value;
    final profileImageUrl = controller.profileImageUrl.value;

    return Container(
      height: size * 0.35,
      width: size * 0.35,
      margin: EdgeInsets.all(size * 0.02),
      decoration: BoxDecoration(
        color: _hasImage ? null : Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size),
        child: _buildImageWidget(selectedImage, profileImageUrl),
      ),
    );
  }

  // 프로필 이미지 보여주는 위젯
  Widget _buildImageWidget(File? selectedImage, String profileImageUrl) {
    // 선택한 이미지가 있을때
    if (selectedImage != null) {
      return Image.file(selectedImage, fit: BoxFit.cover);
    }
    // 선택한 이미지가 없고 설정한 프로필 사진이 있을 때
    else if (profileImageUrl.isNotEmpty) {
      return Image.network(profileImageUrl, fit: BoxFit.cover);
    }
    // 비어있는 프로필 정보
    else {
      return Icon(
        Icons.person_rounded,
        size: size * 0.18,
        color: Colors.grey[400],
      );
    }
  }

  // 이미지 상태에 따라 나타는 버튼이 다름
  Widget _buildActionButton() {
    final buttonSize = size * 0.12; // 0.12 * width 비율 유지
    return Positioned(
      bottom: 0,
      right: 0,
      child:
          _hasImage
              ? _buildDeleteButton(buttonSize)
              : _buildCameraButton(buttonSize),
    );
  }

  // 설정된 이미지 삭제 버튼
  Widget _buildDeleteButton(double buttonSize) {
    return InkWell(
      onTap: onDelete,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.remove_rounded, size: buttonSize, color: Colors.red),
      ),
    );
  }

  // 사진 선택한다는 카메라 버튼
  Widget _buildCameraButton(double buttonSize) {
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.camera_alt_rounded),
    );
  }

  // 이미지가 있는지 확인
  bool get _hasImage {
    return controller.selectedImage.value != null ||
        controller.profileImageUrl.value.isNotEmpty;
  }
}
