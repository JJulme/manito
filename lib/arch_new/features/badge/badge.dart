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

  final Map<String, int> badgeMap;
  final Map<String, int> badgeComment;

  final int badgeHomeCount; // badgeMissionCount + badgeManitoCount
  final int badgeMissionCount;
  final int badgeManitoCount;
  final int badgePostCount;

  const BadgeState({
    this.badgeByTarget = const {},
    this.badgeTotals = const {},

    this.badgeMap = const {
      'friend_request': 0,
      'post_comment': 0,
      'mission_propose': 0,
      'mission_accept': 0,
      'mission_guess': 0,
    },

    this.badgeComment = const {},
    this.badgeHomeCount = 0,
    this.badgeMissionCount = 0,
    this.badgeManitoCount = 0,
    this.badgePostCount = 0,
  });

  BadgeState copyWith({
    Map<String, Map<String, int>>? badgeByTarget,
    Map<String, int>? badgeTotals,
    Map<String, int>? badgeMap,
    Map<String, int>? badgeComment,
    int? badgeHomeCount,
    int? badgeMissionCount,
    int? badgeManitoCount,
    int? badgePostCount,
  }) {
    return BadgeState(
      badgeByTarget: badgeByTarget ?? this.badgeByTarget,
      badgeTotals: badgeTotals ?? this.badgeTotals,
      badgeMap: badgeMap ?? this.badgeMap,
      badgeComment: badgeComment ?? this.badgeComment,
      badgeHomeCount: badgeHomeCount ?? this.badgeHomeCount,
      badgeMissionCount: badgeMissionCount ?? this.badgeMissionCount,
      badgeManitoCount: badgeManitoCount ?? this.badgeManitoCount,
      badgePostCount: badgePostCount ?? this.badgePostCount,
    );
  }

  // Helper 메서드
  int getTotalBadgeCount(String typeId) {
    if (badgeMap.containsKey(typeId)) {
      return badgeMap[typeId] ?? 0;
    }
    return badgeComment[typeId] ?? 0;
  }

  // 뱃지 값 증가 - 포그라운드에서 사용
  BadgeState updateBadgeCount(String type, int count) {
    final newBadgeMap = Map<String, int>.from(badgeMap);
    final newBadgeComment = Map<String, int>.from(badgeComment);

    if (badgeMap.containsKey(type)) {
      newBadgeMap[type] = count;
    } else {
      newBadgeComment[type] = count;
    }

    return copyWith(badgeMap: newBadgeMap, badgeComment: newBadgeComment);
  }

  BadgeState recalculateCount() {
    // Mission 뱃지 합산
    final newBadgeMissionCount =
        (badgeMap['mission_accept'] ?? 0) + (badgeMap['mission_guess'] ?? 0);
    final newBadgeManitoCount = badgeMap['mission_propose'] ?? 0;
    final newBadgeHomeCount = newBadgeMissionCount + newBadgeManitoCount;

    // Post 뱃지 합산
    int totalPostCount = 0;
    badgeComment.forEach((key, value) {
      totalPostCount += value;
    });

    return copyWith(
      badgeHomeCount: newBadgeHomeCount,
      badgeMissionCount: newBadgeMissionCount,
      badgeManitoCount: newBadgeManitoCount,
      badgePostCount: totalPostCount,
    );
  }
}
