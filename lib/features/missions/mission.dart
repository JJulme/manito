import 'package:manito/features/profiles/profile.dart';

// ========== Model ==========
class MyMission {
  final String id;
  final List<FriendProfile> friendProfiles;
  final String status;
  final String contentType;
  final DateTime? acceptDeadline;
  final DateTime deadline;
  final DateTime createdAt;

  MyMission({
    required this.id,
    required this.friendProfiles,
    required this.status,
    required this.contentType,
    this.acceptDeadline,
    required this.deadline,
    required this.createdAt,
  });

  factory MyMission.fromJson(
    Map<String, dynamic> json,
    List<FriendProfile> friendProfiles,
  ) {
    try {
      return MyMission(
        id:
            json['id'] as String? ??
            (throw FormatException('Mission id is required')),
        friendProfiles: friendProfiles,
        status:
            json['status'] as String? ??
            (throw FormatException('Mission status is required')),
        contentType:
            json['content_type'] as String? ??
            (throw FormatException('Mission content_type is required')),
        acceptDeadline:
            json['accept_deadline'] != null
                ? DateTime.parse(json['accept_deadline'] as String).toLocal()
                : null,
        deadline:
            json['deadline'] != null
                ? DateTime.parse(json['deadline'] as String).toLocal()
                : (throw FormatException('Mission deadline is required')),
        createdAt:
            json['created_at'] != null
                ? DateTime.parse(json['created_at'] as String).toLocal()
                : (throw FormatException('Mission created_at is required')),
      );
    } catch (e) {
      throw FormatException('Failed to parse MyMission: $e');
    }
  }
}

// ========== State ==========
class MyMissionState {
  final List<MyMission> allMissions;
  final List<MyMission> pendingMyMissions;
  final List<MyMission> acceptMyMissions;
  final List<MyMission> completeMyMissions;

  MyMissionState({
    this.allMissions = const [],
    this.pendingMyMissions = const [],
    this.acceptMyMissions = const [],
    this.completeMyMissions = const [],
  });

  MyMissionState copyWith({
    List<MyMission>? allMissions,
    List<MyMission>? pendingMyMissions,
    List<MyMission>? acceptMyMissions,
    List<MyMission>? completeMyMissions,
    bool? isLoading,
    String? error,
  }) {
    return MyMissionState(
      allMissions: allMissions ?? this.allMissions,
      pendingMyMissions: pendingMyMissions ?? this.pendingMyMissions,
      acceptMyMissions: acceptMyMissions ?? this.acceptMyMissions,
      completeMyMissions: completeMyMissions ?? this.completeMyMissions,
    );
  }
}

class MissionCreateState {
  final List<FriendProfile> selectedFriends;
  final List<FriendProfile> confirmedFriends;
  final bool isLoading;
  final String? error;

  MissionCreateState({
    this.selectedFriends = const [],
    this.confirmedFriends = const [],
    this.isLoading = false,
    this.error,
  });

  MissionCreateState copyWith({
    List<FriendProfile>? selectedFriends,
    List<FriendProfile>? confirmedFriends,
    bool? isLoading,
    String? error,
  }) {
    return MissionCreateState(
      selectedFriends: selectedFriends ?? this.selectedFriends,
      confirmedFriends: confirmedFriends ?? this.confirmedFriends,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
