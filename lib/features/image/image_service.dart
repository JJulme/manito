import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider
final imageServiceProvider = Provider<ImageService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ImageService(supabase);
});

class ImageConfig {
  static const int defaultMinWidth = 640;
  static const int defaultQuality = 70;
  static const int pngQuality = 100;
  static const String storageBaseUrl =
      'https://rkfdbtdicxarrctsvmif.supabase.co/storage/v1/object/public/';
}

class ImageService {
  final SupabaseClient _supabase;
  ImageService(this._supabase);

  /// 이미지 압축
  Future<File> compressImage(
    File originalFile, {
    int? minWidth,
    int? quality,
  }) async {
    final String extension = path.extension(originalFile.path).toLowerCase();

    final CompressFormat format = _getCompressFormat(extension);
    final String targetExtension = _getTargetExtension(extension);
    final int compressionQuality =
        format == CompressFormat.png
            ? ImageConfig.pngQuality
            : (quality ?? ImageConfig.defaultQuality);

    final Uint8List compressedData =
        await FlutterImageCompress.compressWithList(
          await originalFile.readAsBytes(),
          format: format,
          minWidth: minWidth ?? ImageConfig.defaultMinWidth,
          quality: compressionQuality,
        );

    return await _saveCompressedImage(compressedData, targetExtension);
  }

  /// 이미지 업로드
  Future<String> uploadImage({
    required File file,
    required String bucket,
    required String fileName,
  }) async {
    try {
      final imageBucket = _supabase.storage.from(bucket);
      final String path = await imageBucket.upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      return ImageConfig.storageBaseUrl + path;
    } catch (e) {
      debugPrint('uploadImage Error: $e');
      rethrow;
    }
  }

  /// 여러 이미지 업로드
  Future<List<String>> uploadImages({
    required List<AssetEntity> assets,
    required String bucket,
    required String prefix,
  }) async {
    List<String> uploadedUrls = [];

    for (AssetEntity asset in assets) {
      final file = await asset.originFile;
      if (file == null) continue;

      try {
        // 압축
        final compressedFile = await compressImage(file);
        // 파일명 생성
        final fileName = _generateFileName(prefix);
        // 업로드
        final url = await uploadImage(
          file: compressedFile,
          bucket: bucket,
          fileName: fileName,
        );

        uploadedUrls.add(url);
      } catch (e) {
        debugPrint('Image upload failed for asset: $e');
        // 하나 실패해도 계속 진행
      }
    }

    return uploadedUrls;
  }

  // Private helpers
  CompressFormat _getCompressFormat(String extension) {
    switch (extension) {
      case '.png':
        return CompressFormat.png;
      case '.heic':
      case '.heif':
      case '.jpg':
      case '.jpeg':
        return CompressFormat.jpeg;
      default:
        throw UnsupportedError('지원하지 않는 이미지 형식: $extension');
    }
  }

  String _getTargetExtension(String extension) {
    return (extension == '.heic' || extension == '.heif') ? '.jpeg' : extension;
  }

  String _generateFileName(String prefix) {
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}.png';
  }

  Future<File> _saveCompressedImage(Uint8List data, String extension) async {
    final String tempDir = (await getTemporaryDirectory()).path;
    final String path =
        '$tempDir/${DateTime.now().millisecondsSinceEpoch}$extension';
    final File file = File(path);
    await file.writeAsBytes(data);
    return file;
  }
}
