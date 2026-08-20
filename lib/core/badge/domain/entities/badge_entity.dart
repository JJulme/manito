class BadgeEntity {
  final String type;
  final String typeId;
  final int count;

  const BadgeEntity({
    required this.type,
    required this.typeId,
    required this.count,
  });

  BadgeEntity copyWith({String? type, String? typeId, int? count}) {
    return BadgeEntity(
      type: type ?? this.type,
      typeId: typeId ?? this.typeId,
      count: count ?? this.count,
    );
  }
}

class BadgeState {
  final Map<String, Map<String, int>> badgeByTarget;
  final Map<String, int> badgeTotals;

  final int badgeHomeCount;
  final int badgeMissionCount;
  final int badgeManitoCount;
  final int badgePostCount;

  const BadgeState({
    this.badgeByTarget = const {},
    this.badgeTotals = const {},
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

  int getTotalBadgeCount(String type) {
    return badgeTotals[type] ?? 0;
  }

  int getBadgeCountByTypeId(String type, String typeId) {
    return badgeByTarget[type]?[typeId] ?? 0;
  }
}
