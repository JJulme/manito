import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/badge/domain/entities/badge_entity.dart';
import 'package:manito/core/badge/domain/repositories/repository_provider.dart';
import 'package:manito/features_new/manito/presentation/providers/manito_provider.dart';
import 'package:manito/features_new/missions/presentation/providers/missions_provider.dart';

// ========== Notifier Provider ==========
final badgeProvider = AsyncNotifierProvider<BadgeNotifier, BadgeState>(
  BadgeNotifier.new,
);

// Watch helpers
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
      return await _fetchBadgesInternal();
    } catch (e) {
      debugPrint('BadgeNotifier.build Error: $e');
      return const BadgeState();
    }
  }

  Future<BadgeState> _fetchBadgesInternal() async {
    final repository = ref.read(badgeRepositoryProvider);
    final badges = await repository.fetchBadges();

    final badgeByTarget = <String, Map<String, int>>{};
    final badgeTotals = <String, int>{};

    for (final badge in badges) {
      badgeTotals[badge.type] = (badgeTotals[badge.type] ?? 0) + badge.count;

      badgeByTarget.putIfAbsent(badge.type, () => <String, int>{});
      final targetMap = badgeByTarget[badge.type]!;
      targetMap[badge.typeId] = (targetMap[badge.typeId] ?? 0) + badge.count;
    }

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

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  void incrementBadgeLocally(String type, String typeId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final newBadgeByTarget = Map<String, Map<String, int>>.from(
      currentState.badgeByTarget.map(
        (key, value) => MapEntry(key, Map<String, int>.from(value)),
      ),
    );

    final targetMap = newBadgeByTarget[type] ?? <String, int>{};
    final currentCount = targetMap[typeId] ?? 0;
    targetMap[typeId] = currentCount + 1;
    newBadgeByTarget[type] = targetMap;

    final newBadgeTotals = Map<String, int>.from(currentState.badgeTotals);
    newBadgeTotals[type] = targetMap.values.fold(0, (a, b) => a + b);

    state = AsyncValue.data(
      _calculateBadgeCounts(newBadgeByTarget, newBadgeTotals),
    );
  }

  Future<void> resetBadgeCount(String type, {String? typeId}) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    try {
      final currentCount = currentState.getTotalBadgeCount(type);
      if (currentCount == 0) return;

      final newBadgeByTarget = Map<String, Map<String, int>>.from(
        currentState.badgeByTarget.map(
          (key, value) => MapEntry(key, Map<String, int>.from(value)),
        ),
      );

      if (typeId == null) {
        newBadgeByTarget[type] = {};
      } else {
        final targetMap = newBadgeByTarget[type] ?? <String, int>{};
        targetMap[typeId] = 0;
        newBadgeByTarget[type] = targetMap;
      }

      final newBadgeTotals = Map<String, int>.from(currentState.badgeTotals);
      final targetMap = newBadgeByTarget[type] ?? {};
      newBadgeTotals[type] = targetMap.values.fold(0, (a, b) => a + b);

      state = AsyncValue.data(
        _calculateBadgeCounts(newBadgeByTarget, newBadgeTotals),
      );

      final repository = ref.read(badgeRepositoryProvider);
      await repository.resetBadgeCount(type, typeId: typeId);
    } catch (e) {
      debugPrint('BadgeNotifier.resetBadgeCount Error: $e');
      rethrow;
    }
  }

  Future<void> syncBadgesAndDetectChange() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _previousState = state.valueOrNull;
      final newState = await _fetchBadgesInternal();

      if (_previousState != null) {
        _detectAndHandleChanges(_previousState!, newState);
      }

      return newState;
    });
  }

  void _detectAndHandleChanges(BadgeState oldState, BadgeState newState) {
    final changedBadges = <String, Map<String, int>>{};

    newState.badgeByTarget.forEach((type, typeIdMap) {
      final oldTypeMap = oldState.badgeByTarget[type] ?? {};

      typeIdMap.forEach((typeId, newCount) {
        final oldCount = oldTypeMap[typeId] ?? 0;

        if (newCount != oldCount) {
          changedBadges.putIfAbsent(type, () => {});
          changedBadges[type]![typeId] = newCount - oldCount;
        }
      });

      oldTypeMap.forEach((typeId, oldCount) {
        if (!typeIdMap.containsKey(typeId) && oldCount != 0) {
          changedBadges.putIfAbsent(type, () => {});
          changedBadges[type]![typeId] = -oldCount;
        }
      });
    });

    if (changedBadges.isNotEmpty) {
      _handleBadgeChanges(changedBadges);
    }
  }

  void _handleBadgeChanges(Map<String, Map<String, int>> changedBadges) {
    changedBadges.forEach((type, typeIdChanges) {
      typeIdChanges.forEach((typeId, difference) {
        if (difference > 0) {
          debugPrint(
            '새로운 뱃지 감지: type=$type, typeId=$typeId, count=$difference',
          );

          switch (type) {
            case 'friend_request':
              break;
            case 'mission_propose':
              ref.read(manitoListProvider.notifier).fetchProposeList();
              break;
            case 'mission_accept':
              ref.read(missionListProvider.notifier).refresh();
              break;
            case 'mission_guess':
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
