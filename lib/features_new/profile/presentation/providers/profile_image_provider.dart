import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manito/core/utils/logger.dart';
import 'package:manito/features_new/profile/presentation/providers/my_profile_provider.dart';

// ========== State ==========
class ProfileImageState {
  final File? selectedImage;
  final String profileImageUrl;

  ProfileImageState({this.selectedImage, this.profileImageUrl = ''});
}

// ========== Notifier ==========
class ProfileImageNotifier extends Notifier<ProfileImageState> {
  @override
  ProfileImageState build() {
    final user = ref.watch(myProfileProvider).value;
    return ProfileImageState(profileImageUrl: user?.profileImageUrl ?? '');
  }

  // 이미지 선택
  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        state = ProfileImageState(
          selectedImage: File(pickedFile.path),
          profileImageUrl: state.profileImageUrl,
        );
      }
    } catch (e) {
      Log.e('$e');
    }
  }

  void deleteImage() {
    state = ProfileImageState(selectedImage: null, profileImageUrl: '');
  }
}

// ========== Provider ==========
final profileImageProvider =
    NotifierProvider<ProfileImageNotifier, ProfileImageState>(() {
      return ProfileImageNotifier();
    });
