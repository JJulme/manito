// ========== Model ==========

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
}
