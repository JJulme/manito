import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features/badge/badge.dart';
import 'package:manito/features/badge/badge_service.dart';
import 'package:manito/features/error/error_provider.dart';
import 'package:manito/features/manito/manito_provider.dart';
import 'package:manito/features/missions/mission_provider.dart';

// ========== Service Provider ==========
final badgeServiceProvider = Provider<BadgeService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return BadgeService(supabase);
});

// ========== Notifier Provider ==========
final badgeProvider = AsyncNotifierProvider<BadgeNotifier, BadgeState>(
  BadgeNotifier.new,
);

// 특정 뱃지만 watch하는 프로바이더
final badgeMissionCountProvider = Provider<int>((ref) {
  return ref.watch(badgeProvider).valueOrNull?.badgeMissionCount ?? 0;
});

final badgeManitoCountProvider = Provider<int>((ref) {
  return ref.watch(badgeProvider).valueOrNull?.badgeManitoCount ?? 0;
});

final badgeHomeCountProvider = Provider<int>((ref) {
  return ref.watch(badgeProvider).valueOrNull?.badgeHomeCount ?? 0;
});

final badgePostCountProvider = Provider<int>((ref) {
  return ref.watch(badgeProvider).valueOrNull?.badgePostCount ?? 0;
});

final specificBadgeProvider = Provider.family<int, String>((ref, type) {
  return ref.watch(badgeProvider).valueOrNull?.getTotalBadgeCount(type) ?? 0;
});

final specificBadgeByIdProvider =
    Provider.family<int, ({String type, String typeId})>((ref, param) {
      return ref
              .watch(badgeProvider)
              .valueOrNull
              ?.getBadgeCountByTypeId(param.type, param.typeId) ??
          0;
    });

// ========== Notifier ==========
class BadgeNotifier extends AsyncNotifier<BadgeState> {
  BadgeState? _previousState;

  @override
  Future<BadgeState> build() async {
    final currentUserId = ref.watch(currentUserProvider)?.id;
    if (currentUserId == null) return const BadgeState();
    try {
      // 앱 시작 시 뱃지 데이터 자동 로드
      return await _fetchBadgesInternal();
    } catch (e) {
      debugPrint('BadgeNotifier.build Error: $e');
      return const BadgeState();
    }
  }

  /// 내부용 뱃지 로드 (재사용)
  Future<BadgeState> _fetchBadgesInternal() async {
    final service = ref.read(badgeServiceProvider);
    final badges = await service.fetchBadges();

    final badgeByTarget = <String, Map<String, int>>{};
    final badgeTotals = <String, int>{};

    for (final badge in badges) {
      // 타입별 합산
      badgeTotals[badge.type] = (badgeTotals[badge.type] ?? 0) + badge.count;

      // type_id별 저장
      badgeByTarget.putIfAbsent(badge.type, () => <String, int>{});
      final targetMap = badgeByTarget[badge.type]!;
      targetMap[badge.typeId] = (targetMap[badge.typeId] ?? 0) + badge.count;
    }

    // 카테고리별 합계 계산
    final badgeMissionCount =
        (badgeTotals['mission_accept'] ?? 0) +
        (badgeTotals['mission_guess'] ?? 0);
    final badgeManitoCount = badgeTotals['mission_propose'] ?? 0;
    final badgePostCount = badgeTotals['post_comment'] ?? 0;
    final badgeHomeCount = badgeMissionCount + badgeManitoCount;

    return BadgeState(
      badgeByTarget: badgeByTarget,
      badgeTotals: badgeTotals,
      badgeMissionCount: badgeMissionCount,
      badgeManitoCount: badgeManitoCount,
      badgePostCount: badgePostCount,
      badgeHomeCount: badgeHomeCount,
    );
  }

  // 뱃지 계산
  BadgeState _calculateBadgeCounts(
    Map<String, Map<String, int>> badgeByTarget,
    Map<String, int> badgeTotals,
  ) {
    final badgeMissionCount =
        (badgeTotals['mission_accept'] ?? 0) +
        (badgeTotals['mission_guess'] ?? 0);
    final badgeManitoCount = badgeTotals['mission_propose'] ?? 0;
    final badgePostCount = badgeTotals['post_comment'] ?? 0;
    final badgeHomeCount = badgeMissionCount + badgeManitoCount;

    return BadgeState(
      badgeByTarget: badgeByTarget,
      badgeTotals: badgeTotals,
      badgeMissionCount: badgeMissionCount,
      badgeManitoCount: badgeManitoCount,
      badgePostCount: badgePostCount,
      badgeHomeCount: badgeHomeCount,
    );
  }

  /// 뱃지 새로고침
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// 로컬 상태에서만 +1 - FirebaseMessaging.onMessage.listen
  void incrementBadgeLocally(String type, String typeId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // ✅ 업데이트 로직 (Notifier에서 처리)
    final newBadgeByTarget = Map<String, Map<String, int>>.from(
      currentState.badgeByTarget.map(
        (key, value) => MapEntry(key, Map<String, int>.from(value)),
      ),
    );

    final targetMap = newBadgeByTarget[type] ?? <String, int>{};
    final currentCount = targetMap[typeId] ?? 0;
    targetMap[typeId] = currentCount + 1;
    newBadgeByTarget[type] = targetMap;

    // 총합 재계산
    final newBadgeTotals = Map<String, int>.from(currentState.badgeTotals);
    newBadgeTotals[type] = targetMap.values.fold(0, (a, b) => a + b);

    // 새 상태 생성
    state = AsyncValue.data(
      _calculateBadgeCounts(newBadgeByTarget, newBadgeTotals),
    );
  }

  /// 뱃지 초기화
  Future<void> resetBadgeCount(String type, {String? typeId}) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    try {
      final currentCount = currentState.getTotalBadgeCount(type);
      if (currentCount == 0) return;

      // ✅ 업데이트 로직
      final newBadgeByTarget = Map<String, Map<String, int>>.from(
        currentState.badgeByTarget.map(
          (key, value) => MapEntry(key, Map<String, int>.from(value)),
        ),
      );

      if (typeId == null) {
        // 전체 type 초기화
        newBadgeByTarget[type] = {};
      } else {
        // 특정 typeId만 초기화
        final targetMap = newBadgeByTarget[type] ?? <String, int>{};
        targetMap[typeId] = 0;
        newBadgeByTarget[type] = targetMap;
      }

      // 총합 재계산
      final newBadgeTotals = Map<String, int>.from(currentState.badgeTotals);
      final targetMap = newBadgeByTarget[type] ?? {};
      newBadgeTotals[type] = targetMap.values.fold(0, (a, b) => a + b);

      // 로컬 상태 업데이트
      state = AsyncValue.data(
        _calculateBadgeCounts(newBadgeByTarget, newBadgeTotals),
      );

      // 서버 업데이트
      final service = ref.read(badgeServiceProvider);
      await service.resetBadgeCount(type, typeId: typeId);
    } catch (e) {
      debugPrint('BadgeNotifier.resetBadgeCount Error: $e');
      rethrow;
    }
  }

  /// 뱃지 동기화 및 변경사항 감지 - AppLifecycleState.resumed
  Future<void> syncBadgesAndDetectChange() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // 이전 상태 저장
      _previousState = state.valueOrNull;

      // 새 뱃지 가져오기
      final newState = await _fetchBadgesInternal();

      // 변경사항 감지
      if (_previousState != null) {
        _detectAndHandleChanges(_previousState!, newState);
      }

      return newState;
    });
  }

  /// 변경사항 감지 (private)
  void _detectAndHandleChanges(BadgeState oldState, BadgeState newState) {
    final changedBadges = <String, Map<String, int>>{};

    // badgeByTarget 변경사항 확인
    newState.badgeByTarget.forEach((type, typeIdMap) {
      final oldTypeMap = oldState.badgeByTarget[type] ?? {};

      typeIdMap.forEach((typeId, newCount) {
        final oldCount = oldTypeMap[typeId] ?? 0;

        if (newCount != oldCount) {
          changedBadges.putIfAbsent(type, () => {});
          changedBadges[type]![typeId] = newCount - oldCount;
        }
      });

      // 이전에 있었는데 지금 없는 경우
      oldTypeMap.forEach((typeId, oldCount) {
        if (!typeIdMap.containsKey(typeId) && oldCount != 0) {
          changedBadges.putIfAbsent(type, () => {});
          changedBadges[type]![typeId] = -oldCount;
        }
      });
    });

    // 변경된 뱃지가 있으면 처리
    if (changedBadges.isNotEmpty) {
      _handleBadgeChanges(changedBadges);
    }
  }

  /// 변경된 뱃지 처리 (private)
  void _handleBadgeChanges(Map<String, Map<String, int>> changedBadges) {
    changedBadges.forEach((type, typeIdChanges) {
      typeIdChanges.forEach((typeId, difference) {
        if (difference > 0) {
          debugPrint(
            '새로운 뱃지 감지: type=$type, typeId=$typeId, count=$difference',
          );

          switch (type) {
            case 'friend_request':
              // 친구 신청 처리
              break;
            case 'mission_propose':
              // 미션 제의 처리
              ref.read(manitoListProvider.notifier).fetchProposeList();
              break;
            case 'mission_accept':
              // 미션 수락 처리
              ref.read(missionListProvider.notifier).refresh();
              break;
            case 'mission_guess':
              // 미션 추측 처리
              ref.read(missionListProvider.notifier).refresh();
              break;
            case 'post_comment':
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
