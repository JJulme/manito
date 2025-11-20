import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/features/profiles/profile.dart';
import 'package:manito/features/profiles/profile_provider.dart';
import 'package:manito/main.dart';
import 'package:manito/share/custom_toast.dart';
import 'package:manito/share/sub_appbar.dart';
import 'package:manito/widgets/profile_image_view.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  final bool canGoback;
  const ProfileEditScreen({super.key, this.canGoback = true});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameFormKey = GlobalKey<FormState>();
  final _replyFormKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _statusController;
  late TextEditingController _replyController;

  @override
  void initState() {
    super.initState();
    final userProfile = ref.read(userProfileProvider).value!.userProfile!;
    _nameController = TextEditingController(text: userProfile.nickname);
    _statusController = TextEditingController(text: userProfile.statusMessage);
    _replyController = TextEditingController(text: userProfile.autoReply);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    _replyController.dispose();
    super.dispose();
  }

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

  /// 자동응답 입력 검증 함수
  String? _validateReply(String? value) {
    // 값이 비어있는지 확인
    if (value == null || value.isEmpty) {
      return '5글자 이상 입력해주세요.';
    }
    final String trimmedValue = value.trim();
    if (trimmedValue.length < 5) {
      return '5글자 이상 입력해주세요.';
    }
    return null;
  }

  void _handlePickImage() {
    ref.read(profileImageProvider.notifier).pickImage();
  }

  void _handleDeleteImage() {
    ref.read(profileImageProvider.notifier).deleteImage();
  }

  // 프로필 정보 업데이트
  Future<void> _handleButton(ProfileEditState state) async {
    if ((_nameFormKey.currentState?.validate() ?? false) &&
        (_replyFormKey.currentState?.validate() ?? false)) {
      await ref
          .read(profileEditProvider.notifier)
          .updateProfile(
            nickname: _nameController.text,
            statusMessage: _statusController.text,
            autoReply: _replyController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(profileImageProvider);
    final editAsync = ref.watch(profileEditProvider);
    ref.listen<AsyncValue<ProfileEditState>>(profileEditProvider, (prev, next) {
      if ((prev?.isLoading == true) &&
          (next.hasError == false) &&
          next.hasValue) {
        ref.read(userProfileProvider.notifier).refresh();
        context.pop();
      } else if (next.hasError) {
        context.pop();
        customToast(msg: '프로필 수정 실패: ${next.error.toString()}');
      }
    });
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: SubAppbar(
          title: Text('프로필 수정'),
          actions: [_buildUpdateBtn(editAsync)],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                  child: Column(
                    children: [
                      _buildProfileImageSection(imageState),
                      SizedBox(height: width * 0.06),
                      _buildNameField(_nameController),
                      SizedBox(height: width * 0.06),
                      _buildStatusField(_statusController),
                      SizedBox(height: width * 0.06),
                      _buildReplyField(_replyController),
                      SizedBox(height: width * 0.02),
                      _buildReplyInfo(),
                    ],
                  ),
                ),
              ),
              if (editAsync.isLoading) _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // 아이콘 버튼
  IconButton _buildUpdateBtn(AsyncValue<ProfileEditState> editAsync) {
    return editAsync.when(
      loading: () {
        return IconButton(
          icon: const CircularProgressIndicator(),
          onPressed: null,
        );
      },
      error: (error, stackTrace) {
        return IconButton(
          icon: Icon(Icons.check, color: Theme.of(context).disabledColor),
          onPressed: null,
        );
      },
      data: (state) {
        return IconButton(
          icon: Icon(Icons.check, color: Colors.green),
          onPressed: () => _handleButton(state),
        );
      },
    );
  }

  // 프로필 이미지 화면
  Widget _buildProfileImageSection(ProfileImageState state) {
    return GestureDetector(
      onTap: _handlePickImage,
      onLongPress: _handleDeleteImage,
      child: Stack(
        children: [
          _buildProfileImage(width * 0.3, state),
          Positioned(
            right: 0,
            bottom: 0,
            child: _buildCameraButton(width * 0.09),
          ),
        ],
      ),
    );
  }

  // 프로필 이미지
  Widget _buildProfileImage(double imageSize, ProfileImageState state) {
    // 앨범에서 선택한 이미지가 있을 때
    if (state.selectedImage != null) {
      return Container(
        width: imageSize,
        height: imageSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Image.file(
            state.selectedImage!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    // 앨범에서 선택한 이미지가 없고 프로필 사진이 있을 때
    else {
      return ProfileImageView(
        size: imageSize,
        profileImageUrl: state.profileImageUrl,
      );
    }
  }

  // 카메라 아이콘
  Widget _buildCameraButton(double buttonSize) {
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.camera_alt_rounded),
    );
  }

  // 이름 입력창
  Widget _buildNameField(TextEditingController nameController) {
    return Form(
      key: _nameFormKey,
      child: TextFormField(
        maxLength: 10,
        controller: nameController,
        validator: (value) => _validateNickname(value),
        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\n]'))],
        decoration: InputDecoration(
          labelText: context.tr('modify_screen.name'),
        ),
        buildCounter:
            (
              context, {
              required currentLength,
              required isFocused,
              required maxLength,
            }) => null,
      ),
    );
  }

  // 상태메시지 입력창
  Widget _buildStatusField(TextEditingController statusController) {
    return TextFormField(
      minLines: 1,
      maxLines: 2,
      maxLength: 30,
      controller: statusController,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\n]'))],
      decoration: InputDecoration(
        labelText: context.tr("modify_screen.status_message"),
      ),
      buildCounter:
          (
            context, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) => null,
    );
  }

  // 자동응답 입력창
  Widget _buildReplyField(TextEditingController replyController) {
    return Form(
      key: _replyFormKey,
      child: TextFormField(
        minLines: 1,
        maxLines: 5,
        maxLength: 40,
        controller: replyController,
        validator: (value) => _validateReply(value),
        decoration: InputDecoration(labelText: '자동응답'),
        buildCounter:
            (
              context, {
              required currentLength,
              required isFocused,
              required maxLength,
            }) => null,
      ),
    );
  }

  // 자동응답 설명창
  Widget _buildReplyInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.02),
      child: Text(
        '자동응답은 미션을 수락하고 제한시간까지 아무것도 입력 못했을 때 자동으로 전송됩니다.',
        style: Theme.of(context).textTheme.labelLarge,
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
