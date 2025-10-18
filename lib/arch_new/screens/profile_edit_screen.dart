import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/arch_new/features/profiles/profile.dart';
import 'package:manito/arch_new/features/profiles/profile_provider.dart';
import 'package:manito/arch_new/share/sub_appbar.dart';
import 'package:manito/widgets/common/custom_toast.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _statusController;

  @override
  void initState() {
    super.initState();
    final profileState = ref.read(userProfileProvider);
    _nameController = TextEditingController(
      text: profileState.userProfile!.nickname,
    );
    _statusController = TextEditingController(
      text: profileState.userProfile!.statusMessage,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(profileEditProvider.notifier)
          .setInitialProfileImage(profileState.userProfile!.profileImageUrl!);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
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

  Future<void> _handleButton(
    double width,
    ProfileEditState state,
    ProfileEditNotifier notifier,
  ) async {
    await notifier.updateProfile(
      nickname: _nameController.text,
      statusMessage: _statusController.text,
    );
    if (!mounted) return;
    if (state.error != null) {
      Navigator.pop(context, false);
      customToast(width: width, msg: state.error.toString());
    } else {
      ref.read(userProfileProvider.notifier).getProfile();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final state = ref.watch(profileEditProvider);
    final notifier = ref.read(profileEditProvider.notifier);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: SubAppbar(
          width: width,
          title: Text('프로필 수정'),
          actions: [_buildUpdateBtn(width, state, notifier)],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                  child: Column(
                    children: [
                      _buildProfileImageSection(width, state, notifier),
                      SizedBox(height: width * 0.06),
                      _buildNameField(_nameController),
                      SizedBox(height: width * 0.06),
                      _buildStatusField(_statusController),
                    ],
                  ),
                ),
              ),
              if (state.isLoading) _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // 아이콘 버튼
  IconButton _buildUpdateBtn(
    double width,
    ProfileEditState state,
    ProfileEditNotifier notifier,
  ) {
    return IconButton(
      icon:
          state.isLoading
              ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.grey),
              )
              : Icon(Icons.check, color: Colors.green, size: width * 0.08),
      onPressed: () => _handleButton(width, state, notifier),
    );
  }

  // 프로필 이미지 화면
  Widget _buildProfileImageSection(
    double width,
    ProfileEditState state,
    ProfileEditNotifier notifier,
  ) {
    return GestureDetector(
      onTap: () => notifier.pickImage(),
      onLongPress: () => notifier.deleteImage(),
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
  Widget _buildProfileImage(double imageSize, ProfileEditState state) {
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
      key: _formKey,
      child: TextFormField(
        maxLength: 10,
        validator: _validateNickname,
        controller: nameController,
        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\n]'))],
        decoration: InputDecoration(
          labelText: context.tr('modify_screen.name'),
        ),
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
