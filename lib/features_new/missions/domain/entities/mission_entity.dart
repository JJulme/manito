import 'package:manito/features_new/friends/domain/entities/friend_entity.dart';

// ========== Entities ==========
class MyMissionEntity {
  final String id;
  final List<FriendProfileEntity> friendProfiles;
  final String status;
  final String contentType;
  final DateTime? acceptDeadline;
  final DateTime deadline;
  final DateTime createdAt;

  MyMissionEntity({
    required this.id,
    required this.friendProfiles,
    required this.status,
    required this.contentType,
    this.acceptDeadline,
    required this.deadline,
    required this.createdAt,
  });
}

class MissionCreateSelectionEntity {
  final List<FriendProfileEntity> selectedFriends;
  final List<FriendProfileEntity> confirmedFriends;

  MissionCreateSelectionEntity({
    this.selectedFriends = const [],
    this.confirmedFriends = const [],
  });

  MissionCreateSelectionEntity copyWith({
    List<FriendProfileEntity>? selectedFriends,
    List<FriendProfileEntity>? confirmedFriends,
  }) {
    return MissionCreateSelectionEntity(
      selectedFriends: selectedFriends ?? this.selectedFriends,
      confirmedFriends: confirmedFriends ?? this.confirmedFriends,
    );
  }
}

// ========== State ==========
class MyMissionState {
  final List<MyMissionEntity> allMissions;
  final List<MyMissionEntity> pendingMyMissions;
  final List<MyMissionEntity> acceptMyMissions;
  final List<MyMissionEntity> completeMyMissions;

  MyMissionState({
    this.allMissions = const [],
    this.pendingMyMissions = const [],
    this.acceptMyMissions = const [],
    this.completeMyMissions = const [],
  });

  MyMissionState copyWith({
    List<MyMissionEntity>? allMissions,
    List<MyMissionEntity>? pendingMyMissions,
    List<MyMissionEntity>? acceptMyMissions,
    List<MyMissionEntity>? completeMyMissions,
  }) {
    return MyMissionState(
      allMissions: allMissions ?? this.allMissions,
      pendingMyMissions: pendingMyMissions ?? this.pendingMyMissions,
      acceptMyMissions: acceptMyMissions ?? this.acceptMyMissions,
      completeMyMissions: completeMyMissions ?? this.completeMyMissions,
    );
  }
}
