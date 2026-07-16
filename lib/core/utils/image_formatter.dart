import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:manito/core/utils/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImageFormatter {
  /// 이미지를 리사이징하고 압축하여 임시 파일로 반환합니다.
  static Future<File> compressImage(
    File originalFile, {
    int minWidth = 640,
    int quality = 70,
  }) async {
    final extension = path.extension(originalFile.path).toLowerCase();
    Uint8List? compressedData;
    CompressFormat format = CompressFormat.jpeg;
    String targetExtension = '.jpeg';

    // 1. 형식 확인 및 포맷 결정
    if (extension == '.heic' ||
        extension == '.heif' ||
        extension == '.jpg' ||
        extension == '.jpeg') {
      format = CompressFormat.jpeg;
      targetExtension = '.jpeg';
    } else if (extension == '.png') {
      format = CompressFormat.png;
      targetExtension = '.png';
      quality = 100; // PNG는 무손실 압축 위주
    } else {
      Log.e('지원하지 않는 형식($extension), 원본을 반환합니다.');
      return originalFile;
    }

    // 2. 압축 실행
    compressedData = await FlutterImageCompress.compressWithList(
      await originalFile.readAsBytes(),
      format: format,
      minWidth: minWidth,
      quality: quality,
    );

    // 3. 임시 파일로 저장하여 반환
    final String tempDir = (await getTemporaryDirectory()).path;
    final String tempPath =
        '$tempDir/${DateTime.now().millisecondsSinceEpoch}$targetExtension';

    final File compressedFile = File(tempPath);
    await compressedFile.writeAsBytes(compressedData);

    return compressedFile;
  }
}
