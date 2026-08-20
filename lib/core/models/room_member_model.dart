import 'user_model.dart';
import 'mission_model.dart';
import 'room_model.dart';

class RoomMemberModel {
  final int roomMemberId;
  final String roomId;
  final String userId;
  final String? targetUserId;
  final String joinStatus; // '-', '✔️', 'X'
  final int? assignedMissionId;
  final bool isMissionSelected;
  final bool isInviteViewed;
  final DateTime createdAt;
  final UserModel? userProfile;
  final UserModel? targetUserProfile;
  final MissionModel? assignedMission;
  final RoomModel? room;

  const RoomMemberModel({
    required this.roomMemberId,
    required this.roomId,
    required this.userId,
    this.targetUserId,
    required this.joinStatus,
    this.assignedMissionId,
    required this.isMissionSelected,
    required this.isInviteViewed,
    required this.createdAt,
    this.userProfile,
    this.targetUserProfile,
    this.assignedMission,
    this.room,
  });

  factory RoomMemberModel.fromJson(Map<String, dynamic> json) {
    return RoomMemberModel(
      roomMemberId: json['room_member_id'] as int,
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      targetUserId: json['target_user_id'] as String?,
      joinStatus: json['join_status'] as String? ?? '-',
      assignedMissionId: json['assigned_mission_id'] as int?,
      isMissionSelected: json['is_mission_selected'] as bool? ?? false,
      isInviteViewed: json['is_invite_viewed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      userProfile: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      targetUserProfile: json['target_user'] != null
          ? UserModel.fromJson(json['target_user'] as Map<String, dynamic>)
          : null,
      assignedMission: json['mission'] != null
          ? MissionModel.fromJson(json['mission'] as Map<String, dynamic>)
          : null,
      room: json['room'] != null
          ? RoomModel.fromJson(json['room'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_member_id': roomMemberId,
      'room_id': roomId,
      'user_id': userId,
      'target_user_id': targetUserId,
      'join_status': joinStatus,
      'assigned_mission_id': assignedMissionId,
      'is_mission_selected': isMissionSelected,
      'is_invite_viewed': isInviteViewed,
      'created_at': createdAt.toIso8601String(),
      'user': userProfile?.toJson(),
      'target_user': targetUserProfile?.toJson(),
      'mission': assignedMission?.toJson(),
      'room': room?.toJson(),
    };
  }
}
