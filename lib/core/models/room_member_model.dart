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
      roomMemberId: (json['room_member_id'] as num?)?.toInt() ?? 0,
      roomId: json['room_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      targetUserId: json['target_user_id'] as String?,
      joinStatus: json['join_status'] as String? ?? '-',
      assignedMissionId: (json['assigned_mission_id'] as num?)?.toInt(),
      isMissionSelected: json['is_mission_selected'] as bool? ?? false,
      isInviteViewed: json['is_invite_viewed'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      userProfile: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      targetUserProfile: json['target_user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['target_user'] as Map<String, dynamic>)
          : null,
      assignedMission: json['mission'] is Map<String, dynamic>
          ? MissionModel.fromJson(json['mission'] as Map<String, dynamic>)
          : null,
      room: json['room'] is Map<String, dynamic>
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
