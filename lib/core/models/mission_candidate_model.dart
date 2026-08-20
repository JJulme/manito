import 'mission_model.dart';

class MissionCandidateModel {
  final int candidateId;
  final int roomMemberId;
  final int candidateMission1Id;
  final int candidateMission2Id;
  final DateTime createdAt;
  final MissionModel? mission1;
  final MissionModel? mission2;

  const MissionCandidateModel({
    required this.candidateId,
    required this.roomMemberId,
    required this.candidateMission1Id,
    required this.candidateMission2Id,
    required this.createdAt,
    this.mission1,
    this.mission2,
  });

  factory MissionCandidateModel.fromJson(Map<String, dynamic> json) {
    return MissionCandidateModel(
      candidateId: json['candidate_id'] as int,
      roomMemberId: json['room_member_id'] as int,
      candidateMission1Id: json['candidate_mission_1_id'] as int,
      candidateMission2Id: json['candidate_mission_2_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      mission1: json['mission_1'] != null
          ? MissionModel.fromJson(json['mission_1'] as Map<String, dynamic>)
          : null,
      mission2: json['mission_2'] != null
          ? MissionModel.fromJson(json['mission_2'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'candidate_id': candidateId,
      'room_member_id': roomMemberId,
      'candidate_mission_1_id': candidateMission1Id,
      'candidate_mission_2_id': candidateMission2Id,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
