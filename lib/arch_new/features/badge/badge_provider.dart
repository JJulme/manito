import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/arch_new/core/providers.dart';
import 'package:manito/arch_new/features/badge/badge.dart';
import 'package:manito/arch_new/features/badge/badge_service.dart';

// ========== Service Provider ==========
final badgeServiceProvider = Provider<BadgeService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return BadgeService(supabase);
});

// ========== Notifier Provider ==========
final badgeProvider = StateNotifierProvider<BadgeNotifier, BadgeState>((ref) {
  final badgeService = ref.watch(badgeServiceProvider);
  return BadgeNotifier(badgeService);
});

// 특정 뱃지만 watch하는 프로바이더
final badgeMissionCountProvider = Provider<int>((ref) {
  final state = ref.watch(badgeProvider);
  return state.badgeMissionCount;
});

final badgePostCountProvider = Provider<int>((ref) {
  final state = ref.watch(badgeProvider);
  return state.badgePostCount;
});

final specificBadgeProvider = Provider.family<int, String>((ref, badgeType) {
  final state = ref.watch(badgeProvider);
  return state.getTotalBadgeCount(badgeType);
});

// ========== Notifier ==========
class BadgeNotifier extends StateNotifier<BadgeState> {
  final BadgeService _service;
  BadgeNotifier(this._service) : super(const BadgeState());

  BadgeState? _previousState;

  /// 뱃지 목록 초기 로드
  Future<void> fetchBadges() async {
    try {
      final badges = await _service.fetchBadges();

      final badgeByTarget = <String, Map<String, int>>{};
      final badgeTotals = <String, int>{};

      for (final badge in badges) {
        // 1️⃣ 타입별 합산
        badgeTotals[badge.type] = (badgeTotals[badge.type] ?? 0) + badge.count;
        // 2️⃣ type_id별 저장
        badgeByTarget.putIfAbsent(badge.type, () => <String, int>{});
        final targetMap = badgeByTarget[badge.type]!;
        targetMap[badge.typeId] = (targetMap[badge.typeId] ?? 0) + badge.count;
      }

      // 3️⃣ 카테고리별 합계 계산
      final badgeMissionCount =
          (badgeTotals['mission_accept'] ?? 0) +
          (badgeTotals['mission_guess'] ?? 0);

      final badgeManitoCount = (badgeTotals['mission_propose'] ?? 0);
      final badgePostCount = (badgeTotals['post_comment'] ?? 0);
      final badgeHomeCount = badgeMissionCount + badgeManitoCount;

      state = state.copyWith(
        badgeByTarget: badgeByTarget,
        badgeTotals: badgeTotals,
        badgeMissionCount: badgeMissionCount,
        badgeManitoCount: badgeManitoCount,
        badgePostCount: badgePostCount,
        badgeHomeCount: badgeHomeCount,
      );
      // 합산 재계산
      // state = state.recalculateCount();
    } catch (e) {
      debugPrint('BadgeNotifier.fetchBadges Error: $e');
    }
  }

  /// 로컬 상태에서만 +1
  void incrementBadgeLocally(String badgeType) {
    final currentCount = state.getTotalBadgeCount(badgeType);
    state = state.updateBadgeCount(badgeType, currentCount + 1);
    state = state.recalculateCount();
  }

  /// 댓글 뱃지 추가
  void addBadgeComment(String missionId) {
    final newBadgeComment = Map<String, int>.from(state.badgeComment);
    newBadgeComment[missionId] = (newBadgeComment[missionId] ?? 0) + 1;

    state = state.copyWith(badgeComment: newBadgeComment);
    state = state.recalculateCount();
  }

  /// 뱃지 초기화
  Future<void> resetBadgeCount(String badgeType, {String? typeId}) async {
    try {
      // 현재 상태에서 0이 아닌 경우만 처리
      final currentCount = state.getTotalBadgeCount(badgeType);

      if (currentCount != 0) {
        // 로컬 상태 업데이트
        if (typeId == null) {
          // 전체 type 초기화
          state = state.updateBadgeCount(badgeType, 0);
        } else {
          // 특정 type_id만 초기화
          final newBadgeComment = Map<String, int>.from(state.badgeComment);
          newBadgeComment[typeId] = 0;
          state = state.copyWith(badgeComment: newBadgeComment);
        }
        // 로컬 상태 업데이트
        state = state.recalculateCount();

        // 서버 업데이트
        await _service.resetBadgeCount(badgeType, typeId: typeId);
      }
    } catch (e) {
      debugPrint('BadgeNotifier.resetBadgeCount Error: $e');
      rethrow;
    }
  }

  /// 뱃지 동기화 및 변경사항 감지
  Future<void> syncBadgesAndDetectChange() async {
    // 이전 상태 저장
    _previousState = state;

    // 새 뱃지 가져오기
    await fetchBadges();

    // 변경사항 감지
    // 변경된 뱃지 타입들
    final changedBadges = <String, int>{};

    // badgeMap 변경사항 확인
    state.badgeMap.forEach((key, newCount) {
      final oldCount = _previousState!.badgeMap[key] ?? 0;
      if (newCount != oldCount) {
        changedBadges[key] = newCount - oldCount; // 증감량
      }
    });
    // badgeComment 변경사항 확인
    state.badgeComment.forEach((key, newCount) {
      final oldCount = _previousState!.badgeComment[key] ?? 0;
      if (newCount != oldCount) {
        changedBadges[key] = newCount - oldCount;
      }
    });

    // 변경된 뱃지가 있으면 처리
    if (changedBadges.isNotEmpty) {
      _handleBadgeChanges(changedBadges);
    }
  }

  /// 변경된 뱃지 처리
  void _handleBadgeChanges(Map<String, int> changedBadges) {
    changedBadges.forEach((badgeType, difference) {
      if (difference > 0) {
        debugPrint('새로운 뱃지 감지: $badgeType (+$difference)');
        // 필요시 추가 처리 (예: 특정 화면으로 이동 등)
      }
    });
  }
}
