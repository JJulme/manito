import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';

class ModifyScreen extends StatelessWidget {
  ModifyScreen({super.key});

  final ModifyController _controller = Get.put(ModifyController());

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
        String result = await _controller.updateProfile();
        customSnackbar(title: '알림', message: result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Obx(() {
        return Scaffold(
          appBar: AppBar(
            title: Text('프로필 수정'),
            titleSpacing: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Get.back(),
            ),
            actions: [_updateBtn(width)],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 프로필 이미지
                      _profileImage(width),
                      SizedBox(height: 0.06 * width),
                      // 이름
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
                        child: Form(
                          key: _formKey,
                          child: TextFormField(
                            maxLength: 10,
                            validator: _validateNickname,
                            controller: _controller.nameController,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'[\n]')),
                            ],
                            decoration: InputDecoration(labelText: '이름'),
                          ),
                        ),
                      ),
                      SizedBox(height: 0.06 * width),
                      // 상태 메시지
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0.05 * width),
                        child: TextFormField(
                          minLines: 1,
                          maxLines: 2,
                          maxLength: 30,
                          controller: _controller.statusController,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'[\n]')),
                          ],
                          decoration: InputDecoration(labelText: '소개'),
                        ),
                      ),
                    ],
                  ),
                ),
                // 업로드 중 수정 방지
                _controller.isLoading.value
                    ? ModalBarrier(
                      dismissible: false,
                      color: Colors.black.withAlpha((0.5 * 255).round()),
                    )
                    : SizedBox.shrink(),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// 프로필 수정 버튼
  IconButton _updateBtn(double width) {
    return IconButton(
      icon:
          _controller.isLoading.value
              ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              )
              : Icon(Icons.check, color: Colors.green, size: 0.08 * width),
      onPressed: _updateProfile,
    );
  }

  /// 프로필 이미지 설정
  GestureDetector _profileImage(double width) {
    return GestureDetector(
      onTap: _controller.pickImage,
      child: Obx(() {
        // 갤러리에서 선택한 이미지
        var selectedImage = _controller.selectedImage.value;
        // supabae에 저장된 이미지
        var profileImageUrl = _controller.profileImageUrl;
        // 갤러리에서 이미지 선택했을 때
        if (selectedImage != null) {
          return Stack(
            children: [
              // 이미지
              Container(
                height: 0.35 * width,
                width: 0.35 * width,
                margin: EdgeInsets.all(0.02 * width),
                decoration: BoxDecoration(shape: BoxShape.circle),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(width),
                  child: Image.file(selectedImage, fit: BoxFit.cover),
                ),
              ),
              // 삭제 버튼
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: () => _controller.deleteImage(),
                  child: Container(
                    width: 0.12 * width,
                    height: 0.12 * width,
                    alignment: Alignment.bottomRight,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.remove_rounded,
                      size: 0.12 * width,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        // 기존 설정된 이미지
        else if (profileImageUrl.isNotEmpty) {
          return Stack(
            children: [
              // 이미지
              Container(
                height: 0.35 * width,
                width: 0.35 * width,
                margin: EdgeInsets.all(0.02 * width),
                decoration: BoxDecoration(shape: BoxShape.circle),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(width),
                  child: Image.network(
                    profileImageUrl.value,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // 삭제 버튼
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: () => _controller.deleteImage(),
                  child: Container(
                    width: 0.12 * width,
                    height: 0.12 * width,
                    alignment: Alignment.bottomRight,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.remove_rounded,
                      size: 0.12 * width,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        // 이미지 없는 경우
        else {
          return Stack(
            children: [
              Container(
                height: 0.35 * width,
                width: 0.35 * width,
                margin: EdgeInsets.all(0.02 * width),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 0.18 * width,
                  color: Colors.grey[400],
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 0.12 * width,
                  height: 0.12 * width,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded),
                ),
              ),
            ],
          );
        }
      }),
    );
  }
}
