import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features/emoticon/data/custom_emoticon_repository.dart';
import 'package:manito/features/emoticon/data/models/custom_emoticon_model.dart';

/// 현재 로그인 사용자의 이모티콘 전체 목록 (최신순)
final userEmoticonsProvider = FutureProvider.autoDispose<List<CustomEmoticonModel>>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];
  return ref.read(customEmoticonRepositoryProvider).getEmoticonsByUser(userId);
});

/// 이모티콘 총 사용 통계 (개수 + 용량)
final emoticonUsageStatsProvider = FutureProvider.autoDispose<EmoticonUsageStats>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return const EmoticonUsageStats(count: 0, totalBytes: 0);
  final repo = ref.read(customEmoticonRepositoryProvider);
  final count = await repo.getEmoticonCount(userId);
  final totalBytes = await repo.getTotalSizeBytes(userId);
  return EmoticonUsageStats(count: count, totalBytes: totalBytes);
});

/// 실시간 키워드 검색 결과 Provider (Family)
final emoticonKeywordSearchProvider =
    FutureProvider.autoDispose.family<List<CustomEmoticonModel>, String>((ref, keyword) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null || keyword.trim().isEmpty) return [];
  return ref.read(customEmoticonRepositoryProvider).searchByKeyword(userId, keyword);
});

/// 이모티콘 사용 통계 데이터 클래스
class EmoticonUsageStats {
  final int count;
  final int totalBytes;

  const EmoticonUsageStats({required this.count, required this.totalBytes});

  /// 사람이 읽기 좋은 용량 문자열 (예: "1.2 MB", "340 KB")
  String get formattedSize {
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// 요약 문자열 (예: "12개 · 1.2 MB")
  String get summary => '$count개 · $formattedSize';
}

/// 이모티콘 등록/수정/삭제를 위한 서비스 (Provider 무효화 포함)
final emoticonServiceProvider = Provider<EmoticonService>((ref) {
  return EmoticonService(ref);
});

class EmoticonService {
  final Ref _ref;

  EmoticonService(this._ref);

  String? get _userId => _ref.read(currentUserProvider)?.id;

  /// 단일 이모티콘 등록
  Future<CustomEmoticonModel?> addEmoticon({
    required File originalFile,
    required List<String> tags,
  }) async {
    final userId = _userId;
    if (userId == null) return null;

    final result = await _ref.read(customEmoticonRepositoryProvider).addEmoticon(
      userId: userId,
      originalFile: originalFile,
      tags: tags,
    );

    _invalidate();
    return result;
  }

  /// 복수 이모티콘 일괄 등록
  Future<List<CustomEmoticonModel>> addMultipleEmoticons({
    required List<File> originalFiles,
    required List<String> tags,
  }) async {
    final userId = _userId;
    if (userId == null) return [];

    final results = await _ref.read(customEmoticonRepositoryProvider).addMultipleEmoticons(
      userId: userId,
      originalFiles: originalFiles,
      tags: tags,
    );

    _invalidate();
    return results;
  }

  /// 태그 수정
  Future<void> updateTags(String emoticonId, List<String> newTags) async {
    await _ref.read(customEmoticonRepositoryProvider).updateTags(emoticonId, newTags);
    _invalidate();
  }

  /// 태그 추가
  Future<void> addTag(String emoticonId, String tag) async {
    await _ref.read(customEmoticonRepositoryProvider).addTag(emoticonId, tag);
    _invalidate();
  }

  /// 태그 제거
  Future<void> removeTag(String emoticonId, String tag) async {
    await _ref.read(customEmoticonRepositoryProvider).removeTag(emoticonId, tag);
    _invalidate();
  }

  /// 이모티콘 삭제
  Future<void> deleteEmoticon(String emoticonId) async {
    await _ref.read(customEmoticonRepositoryProvider).deleteEmoticon(emoticonId);
    _invalidate();
  }

  void _invalidate() {
    _ref.invalidate(userEmoticonsProvider);
    _ref.invalidate(emoticonUsageStatsProvider);
  }
}
