import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features/badge/badge.dart';
import 'package:manito/features/badge/badge_service.dart';

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

final badgeManitoCountProvider = Provider<int>((ref) {
  final state = ref.watch(badgeProvider);
  return state.badgeManitoCount;
});

final badgeHomeCountProvider = Provider<int>((ref) {
  final state = ref.watch(badgeProvider);
  return state.badgeHomeCount;
});

final badgePostCountProvider = Provider<int>((ref) {
  final state = ref.watch(badgeProvider);
  return state.badgePostCount;
});

final specificBadgeProvider = Provider.family<int, String>((ref, type) {
  final state = ref.watch(badgeProvider);
  return state.getTotalBadgeCount(type);
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
  void incrementBadgeLocally(String type, String typeId) {
    final targetMap = Map<String, int>.from(state.badgeByTarget[type] ?? {});
    final currentTypeIdCount = targetMap[typeId] ?? 0;

    // 특정 typeId의 값을 +1
    state = state.updateBadgeCount(
      type,
      currentTypeIdCount + 1,
      typeId: typeId,
    );
  }

  /// 뱃지 초기화
  Future<void> resetBadgeCount(String type, {String? typeId}) async {
    try {
      final currentCount = state.getTotalBadgeCount(type);

      if (currentCount != 0) {
        // updateBadgeCount를 재사용하여 0으로 업데이트
        if (typeId == null) {
          // 전체 type 초기화
          state = state.updateBadgeCount(type, 0);
        } else {
          // 특정 type_id만 초기화
          state = state.updateBadgeCount(type, 0, typeId: typeId);
        }

        // 서버 업데이트
        await _service.resetBadgeCount(type, typeId: typeId);
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
    final changedBadges = <String, Map<String, int>>{};

    // badgeByTarget 변경사항 확인
    state.badgeByTarget.forEach((type, typeIdMap) {
      final oldTypeMap = _previousState?.badgeByTarget[type] ?? {};

      typeIdMap.forEach((typeId, newCount) {
        final oldCount = oldTypeMap[typeId] ?? 0;

        if (newCount != oldCount) {
          if (!changedBadges.containsKey(type)) {
            changedBadges[type] = {};
          }
          changedBadges[type]![typeId] = newCount - oldCount; // 증감량
        }
      });

      // 이전에 있었는데 지금 없는 경우 (삭제됨)
      oldTypeMap.forEach((typeId, oldCount) {
        if (!typeIdMap.containsKey(typeId) && oldCount != 0) {
          if (!changedBadges.containsKey(type)) {
            changedBadges[type] = {};
          }
          changedBadges[type]![typeId] = -oldCount; // 음수로 표시
        }
      });
    });

    // badgeTotals 변경사항 확인 (추가 검증용)
    state.badgeTotals.forEach((type, newTotal) {
      final oldTotal = _previousState?.badgeTotals[type] ?? 0;

      if (newTotal != oldTotal && !changedBadges.containsKey(type)) {
        debugPrint('Badge total changed for $type: $oldTotal -> $newTotal');
      }
    });

    // 변경된 뱃지가 있으면 처리
    if (changedBadges.isNotEmpty) {
      _handleBadgeChanges(changedBadges);
    }
  }

  // 변경된 뱃지 처리
  void _handleBadgeChanges(Map<String, Map<String, int>> changedBadges) {
    changedBadges.forEach((type, typeIdChanges) {
      typeIdChanges.forEach((typeId, difference) {
        if (difference > 0) {
          debugPrint(
            '새로운 뱃지 감지: type=$type, typeId=$typeId, count=$difference',
          );

          // 필요시 추가 처리 (예: 특정 화면으로 이동, 알림 표시 등)
          switch (type) {
            case 'friend_request':
              // 친구 신청 처리
              break;
            case 'mission_propose':
              // 미션 제의 처리
              break;
            case 'mission_accept':
              // 미션 수락 처리
              break;
            case 'mission_guess':
              // 미션 추측 처리
              break;
            case 'post_comment':
              // 댓글 뱃지 처리
              debugPrint('새로운 댓글: missionId=$typeId');
              break;
          }
        } else if (difference < 0) {
          debugPrint('뱃지 감소: type=$type, typeId=$typeId, count=$difference');
        }
      });
    });
  }
}
