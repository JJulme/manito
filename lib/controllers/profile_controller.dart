import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manito/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileController1 extends GetxController {
  final _supabase = Supabase.instance.client;
  var userProfile = Rx<UserProfile?>(null);
  var profileLoading = false.obs;
  var modifyLoading = false.obs;
  var selectedImage = Rx<File?>(null); // 갤러리에서 가져온 이미지
  var profileImageUrl = ''.obs; // 이미지 삭제하는 경우의 변수

  @override
  void onInit() async {
    super.onInit();
    await getProfile();
  }

  /// 프로필 가져오기
  Future<void> getProfile() async {
    profileLoading.value = true;
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', _supabase.auth.currentUser!.id)
          .single();
      userProfile.value = UserProfile.fromJson(data);
    } on PostgrestException catch (e) {
      debugPrint('getProfile PostgrestException Error: $e');
    } catch (e) {
      debugPrint('getProfile Error: $e');
    } finally {
      profileLoading.value = false;
    }
  }

  /// 수정화면으로 이동할 때 변수 초기화
  void initModifyProfile() {
    profileImageUrl.value = userProfile.value!.profileImageUrl!;
  }

  /// 프로필 정보 수정
  Future<String> updateProfile(
    String nickname,
    String statusMessage,
    // File? image,
  ) async {
    modifyLoading.value = true;
    try {
      final profileTable = _supabase.from('profiles');
      final profileImageBucket = _supabase.storage.from('profile-image');
      String baseUrl =
          '${dotenv.env['SUPABASE_URL']!}/storage/v1/object/public/';
      final updateData = {
        'nickname': nickname,
        'status_message': statusMessage
      };

      // 저장 이미지 이름 설정
      final String fileName = '${_supabase.auth.currentUser!.id}.jpg';

      // 선택한 이미지가 있을 경우
      if (selectedImage.value != null) {
        final String fullPath = await profileImageBucket.upload(
          fileName,
          selectedImage.value!,
          fileOptions: FileOptions(cacheControl: '3600', upsert: true),
        );
        updateData['profile_image_url'] = baseUrl + fullPath;
      }

      // 프로필 이미지 설정 안하는 경우
      else if (selectedImage.value == null && profileImageUrl.value.isEmpty) {
        await profileImageBucket.remove([fileName]);
        updateData['profile_image_url'] = '';
      }

      await profileTable
          .update(updateData)
          .eq('id', _supabase.auth.currentUser!.id);
      Get.back(result: true);
      return '프로필 수정 성공';
    } on StorageException catch (e) {
      debugPrint('updateProfile StorageException Error: $e');
      return '저장 오류: $e';
    } catch (e) {
      debugPrint('updateProfile Error: $e');
      return '알 수 없는 오류: $e';
    } finally {
      modifyLoading.value = false;
    }
  }

  /// 1개의 이미지 선택
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      selectedImage.value = File(xFile.path);
      profileImageUrl.value = '';
    }
  }

  // 이미지 삭제
  void deleteImage() {
    profileImageUrl.value = '';
    selectedImage.value = null;
  }
}
