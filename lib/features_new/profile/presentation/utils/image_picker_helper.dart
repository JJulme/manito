// 사용안함

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:manito/core/utils/logger.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// 사용자가 갤러리에서 사진을 선택하도록 돕는 함수
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? xFile = await _picker.pickImage(source: ImageSource.gallery);
      if (xFile != null) {
        return File(xFile.path);
      }
      return null;
    } catch (e) {
      // 에러 로그 처리
      Log.e('사진 가져오기 실패');
      return null;
    }
  }
}
