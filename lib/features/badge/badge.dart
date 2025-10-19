// ========== Model ==========
import 'package:flutter/material.dart';

class BadgeModel {
  final String type;
  final String typeId;
  final int count;
  const BadgeModel({
    required this.type,
    required this.typeId,
    required this.count,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      type: json['type'] as String,
      typeId: json['type_id'] as String,
      count: json['count'] as int? ?? 0,
    );
  }

  BadgeModel copyWith({String? type, String? typeId, int? count}) {
    return BadgeModel(
      type: type ?? this.type,
      typeId: typeId ?? this.typeId,
      count: count ?? this.count,
    );
  }
}

// ========== State ==========
class BadgeState {
  final Map<String, Map<String, int>> badgeByTarget;
  final Map<String, int> badgeTotals;

  final int badgeHomeCount; // badgeMissionCount + badgeManitoCount
  final int badgeMissionCount;
  final int badgeManitoCount;
  final int badgePostCount;

  const BadgeState({
    this.badgeByTarget = const {},
    this.badgeTotals =
        const {}, // friend_request, post_comment, mission_propose, mission_accept, mission_guess

    this.badgeHomeCount = 0,
    this.badgeMissionCount = 0,
    this.badgeManitoCount = 0,
    this.badgePostCount = 0,
  });

  BadgeState copyWith({
    Map<String, Map<String, int>>? badgeByTarget,
    Map<String, int>? badgeTotals,
    int? badgeHomeCount,
    int? badgeMissionCount,
    int? badgeManitoCount,
    int? badgePostCount,
  }) {
    return BadgeState(
      badgeByTarget: badgeByTarget ?? this.badgeByTarget,
      badgeTotals: badgeTotals ?? this.badgeTotals,
      badgeHomeCount: badgeHomeCount ?? this.badgeHomeCount,
      badgeMissionCount: badgeMissionCount ?? this.badgeMissionCount,
      badgeManitoCount: badgeManitoCount ?? this.badgeManitoCount,
      badgePostCount: badgePostCount ?? this.badgePostCount,
    );
  }

  // Helper 메서드
  int getTotalBadgeCount(String type) {
    return badgeTotals[type] ?? 0;
  }

  // 특정 typeId의 뱃지 개수 조회
  int getBadgeCountByTypeId(String type, String typeId) {
    return badgeByTarget[type]?[typeId] ?? 0;
  }

  // 뱃지 모두 초기화
  BadgeState resetBadgeCount(String type, String typeId) {
    return updateBadgeCount(type, 0, typeId: typeId);
  }

  // 뱃지 증가 (특정 typeId만)
  BadgeState incrementBadge(String type, String typeId) {
    final current = getBadgeCountByTypeId(type, typeId);
    return updateBadgeCount(type, current + 1, typeId: typeId);
  }

  // 뱃지 값 증가 - 포그라운드에서 사용
  BadgeState updateBadgeCount(String type, int count, {String? typeId}) {
    final newBadgeByTarget = badgeByTarget.map(
      (key, value) => MapEntry(key, Map<String, int>.from(value)),
    );
    final newBadgeTotals = Map<String, int>.from(badgeTotals);

    if (count == 0 && typeId == null) {
      // ✅ 같은 type의 모든 뱃지값을 0으로 만들기
      if (newBadgeByTarget.containsKey(type)) {
        final updatedMap = newBadgeByTarget[type]!.map(
          (k, v) => MapEntry(k, 0),
        );
        newBadgeByTarget[type] = updatedMap;
      }
      // 총합도 0으로
      newBadgeTotals[type] = 0;
    } else if (typeId != null) {
      // ✅ 특정 typeId만 업데이트
      final targetMap = Map<String, int>.from(newBadgeByTarget[type] ?? {});
      targetMap[typeId] = count;
      newBadgeByTarget[type] = targetMap;

      // 해당 type의 총합 다시 계산
      newBadgeTotals[type] = targetMap.values.fold(0, (a, b) => a + b);
    } else {
      // count > 0 이고 typeId가 없으면 에러
      debugPrint('BadgeState.updateBadgeCount: typeId가 필요합니다 (count가 0이 아닐 때)');
    }

    return copyWith(
      badgeByTarget: newBadgeByTarget,
      badgeTotals: newBadgeTotals,
    ).recalculateCount();
  }

  // 뱃지 합산
  BadgeState recalculateCount() {
    // Mission 뱃지 합산
    final newBadgeMissionCount =
        (badgeTotals['mission_accept'] ?? 0) +
        (badgeTotals['mission_guess'] ?? 0);
    final newBadgeManitoCount = badgeTotals['mission_propose'] ?? 0;
    final newBadgeHomeCount = newBadgeMissionCount + newBadgeManitoCount;
    final newBadgePostCount = badgeTotals['post_comment'] ?? 0;

    return copyWith(
      badgeHomeCount: newBadgeHomeCount,
      badgeMissionCount: newBadgeMissionCount,
      badgeManitoCount: newBadgeManitoCount,
      badgePostCount: newBadgePostCount,
    );
  }
}
