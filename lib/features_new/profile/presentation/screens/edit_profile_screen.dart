import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/core/widget/common_toast.dart';
import 'package:manito/core/widget/profile_image_view.dart';
import 'package:manito/core/widget/sub_appbar.dart';
import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';
import 'package:manito/features_new/profile/presentation/providers/my_profile_provider.dart';
import 'package:manito/features_new/profile/presentation/providers/profile_image_provider.dart';
import 'package:manito/core/theme/domain/entities/app_theme.dart';
import 'package:manito/main.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final bool canGoBack;
  const EditProfileScreen({super.key, this.canGoBack = true});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameFormKey = GlobalKey<FormState>();
  final _statusFormKey = GlobalKey<FormState>();
  final _replyFormKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _statusController;
  late TextEditingController _replyController;

  @override
  void initState() {
    super.initState();
    final myProfile = ref.read(myProfileProvider).value;
    _nameController = TextEditingController(text: myProfile!.nickname);
    _statusController = TextEditingController(text: myProfile.statusMessage);
    _replyController = TextEditingController(text: myProfile.autoReply);
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

  /// 소개 입력 검증 함수
  String? _validateStatus(String? value) {
    // 값이 비어있는지 확인
    if (value == null || value.isEmpty) {
      return '5글자 이상 입력해주세요.';
    }
    final String trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return '5글자 이상 입력해주세요.';
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

  // 프로필 이미지 선택
  void _handlePickImage() {
    ref.read(profileImageProvider.notifier).pickImage();
  }

  // 프로필 이미지 삭제
  void _handleDeleteImage() {
    ref.read(profileImageProvider.notifier).deleteImage();
  }

  // 프로필 정보 업데이트
  Future<void> _handleButton(ProfileImageState imageState) async {
    if (imageState.selectedImage != null ||
        imageState.profileImageUrl.isNotEmpty) {
      if ((_nameFormKey.currentState?.validate() ?? false) &&
          (_replyFormKey.currentState?.validate() ?? false) &&
          (_statusFormKey.currentState?.validate() ?? false)) {
        ref
            .read(myProfileProvider.notifier)
            .updateProfile(
              nickname: _nameController.text,
              statusMessage: _statusController.text,
              autoReply: _replyController.text,
              imageFile: imageState.selectedImage,
              existingImageUrl: imageState.profileImageUrl,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(profileImageProvider);
    final myProfileAsync = ref.watch(myProfileProvider);
    ref.listen<AsyncValue<MyProfileEntity?>>(myProfileProvider, (prev, next) {
      if (prev?.isLoading == true && next.hasValue && !next.hasError) {
        context.pop();
      }
      if (next.hasError) {
        showCommonToast('프로필 수정 실패: ${next.error.toString()}');
      }
    });
    return PopScope(
      canPop: widget.canGoBack,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: SubAppbar(
            title: Text('프로필 수정'),
            actions: [_buildUpdateBtn(imageState, myProfileAsync)],
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
                if (myProfileAsync.isLoading) _buildLoadingOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 아이콘 버튼
  IconButton _buildUpdateBtn(
    ProfileImageState imageState,
    AsyncValue<MyProfileEntity?> myProfileAsync,
  ) {
    return myProfileAsync.isLoading
        ? IconButton(icon: const CircularProgressIndicator(), onPressed: null)
        : IconButton(
          icon: Icon(Icons.check, color: kSuccess, size: width * 0.07),
          onPressed: () => _handleButton(imageState),
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
        color: ColorScheme.of(context).primaryContainer,
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
    return Form(
      key: _statusFormKey,
      child: TextFormField(
        minLines: 1,
        maxLines: 2,
        maxLength: 30,
        controller: statusController,
        validator: (value) => _validateStatus(value),
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
      ),
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
