import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'models/custom_emoticon_model.dart';

const _boxName = 'custom_emoticons';

final customEmoticonRepositoryProvider = Provider<CustomEmoticonRepository>((ref) {
  return CustomEmoticonRepository();
});

/// 사용자 커스텀 이모티콘 CRUD 저장소 (Hive 로컬 DB + Documents 파일 관리)
class CustomEmoticonRepository {
  Box<CustomEmoticonModel>? _box;

  /// Hive Box 초기화 (앱 시작 시 1회 호출)
  Future<Box<CustomEmoticonModel>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<CustomEmoticonModel>(_boxName);
    return _box!;
  }

  /// 이모티콘 전용 저장 디렉터리 경로
  Future<String> _getEmoticonDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final emoticonDir = Directory(p.join(appDir.path, 'custom_emoticons'));
    if (!await emoticonDir.exists()) {
      await emoticonDir.create(recursive: true);
    }
    return emoticonDir.path;
  }

  // ─── READ ───

  /// 특정 사용자의 모든 이모티콘 조회 (최신 등록 순)
  Future<List<CustomEmoticonModel>> getEmoticonsByUser(String userId) async {
    final box = await _getBox();
    final items = box.values
        .where((e) => e.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// 특정 키워드로 매칭되는 이모티콘 검색
  Future<List<CustomEmoticonModel>> searchByKeyword(String userId, String keyword) async {
    final box = await _getBox();
    final normalized = keyword.trim().toLowerCase();
    if (normalized.isEmpty) return [];

    return box.values
        .where((e) => e.userId == userId && e.matchesKeyword(normalized))
        .toList();
  }

  /// 전체 등록 개수
  Future<int> getEmoticonCount(String userId) async {
    final box = await _getBox();
    return box.values.where((e) => e.userId == userId).length;
  }

  /// 전체 사용 용량 (bytes)
  Future<int> getTotalSizeBytes(String userId) async {
    final box = await _getBox();
    return box.values
        .where((e) => e.userId == userId)
        .fold<int>(0, (sum, e) => sum + e.fileSizeBytes);
  }

  // ─── CREATE ───

  /// 단일 이미지 등록 (갤러리에서 선택 → 300x300 압축 → Documents 저장 → Hive 등록)
  Future<CustomEmoticonModel> addEmoticon({
    required String userId,
    required File originalFile,
    required List<String> tags,
  }) async {
    final box = await _getBox();
    final emoticonDir = await _getEmoticonDir();
    final id = '${userId}_${DateTime.now().millisecondsSinceEpoch}';

    // 1. 이미지 300x300 리사이징 & 압축
    final compressedBytes = await _compressToThumbnail(originalFile);

    // 2. Documents 디렉터리에 저장
    final savedPath = p.join(emoticonDir, '$id.jpg');
    final savedFile = File(savedPath);
    await savedFile.writeAsBytes(compressedBytes);

    // 3. Hive에 메타데이터 저장
    final model = CustomEmoticonModel(
      id: id,
      userId: userId,
      tags: tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
      localImagePath: savedPath,
      fileSizeBytes: compressedBytes.length,
      createdAt: DateTime.now(),
    );

    await box.put(id, model);
    AppLogger.i('Emoticon added: $id, tags: ${model.tags}, size: ${compressedBytes.length}B', tag: 'EMOTICON');

    return model;
  }

  /// 복수 이미지 일괄 등록 (동일 태그 일괄 부여)
  Future<List<CustomEmoticonModel>> addMultipleEmoticons({
    required String userId,
    required List<File> originalFiles,
    required List<String> tags,
  }) async {
    final results = <CustomEmoticonModel>[];
    for (final file in originalFiles) {
      try {
        final model = await addEmoticon(
          userId: userId,
          originalFile: file,
          tags: tags,
        );
        results.add(model);
      } catch (e, s) {
        AppLogger.e('Failed to add emoticon: $e', tag: 'EMOTICON', error: e, stackTrace: s);
      }
    }
    return results;
  }

  // ─── UPDATE ───

  /// 이모티콘 태그 수정
  Future<void> updateTags(String emoticonId, List<String> newTags) async {
    final box = await _getBox();
    final model = box.get(emoticonId);
    if (model == null) return;

    model.tags = newTags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    await model.save();
    AppLogger.i('Emoticon tags updated: $emoticonId → ${model.tags}', tag: 'EMOTICON');
  }

  /// 이모티콘에 태그 추가
  Future<void> addTag(String emoticonId, String tag) async {
    final box = await _getBox();
    final model = box.get(emoticonId);
    if (model == null) return;

    final trimmed = tag.trim();
    if (trimmed.isEmpty || model.tags.contains(trimmed)) return;

    model.tags.add(trimmed);
    await model.save();
    AppLogger.i('Tag added to $emoticonId: $trimmed', tag: 'EMOTICON');
  }

  /// 이모티콘에서 태그 제거
  Future<void> removeTag(String emoticonId, String tag) async {
    final box = await _getBox();
    final model = box.get(emoticonId);
    if (model == null) return;

    model.tags.remove(tag.trim());
    await model.save();
    AppLogger.i('Tag removed from $emoticonId: ${tag.trim()}', tag: 'EMOTICON');
  }

  // ─── DELETE ───

  /// 단일 이모티콘 삭제 (Hive + 디스크 파일)
  Future<void> deleteEmoticon(String emoticonId) async {
    final box = await _getBox();
    final model = box.get(emoticonId);
    if (model == null) return;

    // 디스크 파일 삭제
    try {
      final file = File(model.localImagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      AppLogger.w('Failed to delete emoticon file: $e', tag: 'EMOTICON');
    }

    await box.delete(emoticonId);
    AppLogger.i('Emoticon deleted: $emoticonId', tag: 'EMOTICON');
  }

  /// 특정 사용자의 모든 이모티콘 삭제
  Future<void> deleteAllByUser(String userId) async {
    final box = await _getBox();
    final toDelete = box.values.where((e) => e.userId == userId).toList();

    for (final model in toDelete) {
      try {
        final file = File(model.localImagePath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      await box.delete(model.id);
    }
    AppLogger.i('All emoticons deleted for user: $userId (${toDelete.length} items)', tag: 'EMOTICON');
  }

  // ─── IMAGE COMPRESSION ───

  /// 300x300 이하 JPEG 썸네일로 압축 (약 50KB 이하)
  Future<Uint8List> _compressToThumbnail(File originalFile) async {
    final bytes = await originalFile.readAsBytes();
    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 300,
      minHeight: 300,
      quality: 75,
      format: CompressFormat.jpeg,
    );
    AppLogger.d(
      'Emoticon compressed: ${bytes.length}B → ${compressed.length}B',
      tag: 'EMOTICON',
    );
    return compressed;
  }
}
