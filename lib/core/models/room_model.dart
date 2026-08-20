import 'user_model.dart';

enum RoomStatus {
  waiting('WAITING'),
  preparing('PREPARING'),
  ongoing('ONGOING'),
  ended('ENDED');

  final String value;
  const RoomStatus(this.value);

  static RoomStatus fromString(String val) {
    return RoomStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => RoomStatus.waiting,
    );
  }
}

class RoomModel {
  final String roomId;
  final String hostId;
  final String title;
  final RoomStatus status;
  final String? missionCategory;
  final DateTime? gameStartTime;
  final DateTime? gameEndTime;
  final DateTime createdAt;
  final UserModel? hostProfile;

  const RoomModel({
    required this.roomId,
    required this.hostId,
    this.title = '마니또 대기실',
    required this.status,
    this.missionCategory,
    this.gameStartTime,
    this.gameEndTime,
    required this.createdAt,
    this.hostProfile,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      roomId: json['room_id'] as String,
      hostId: json['host_id'] as String,
      title: json['title'] as String? ?? '마니또 대기실',
      status: RoomStatus.fromString(json['status'] as String),
      missionCategory: json['mission_category'] as String?,
      gameStartTime: json['game_start_time'] != null
          ? DateTime.parse(json['game_start_time'] as String).toLocal()
          : null,
      gameEndTime: json['game_end_time'] != null
          ? DateTime.parse(json['game_end_time'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      hostProfile: json['host'] != null
          ? UserModel.fromJson(json['host'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'host_id': hostId,
      'title': title,
      'status': status.value,
      'mission_category': missionCategory,
      'game_start_time': gameStartTime?.toUtc().toIso8601String(),
      'game_end_time': gameEndTime?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'host': hostProfile?.toJson(),
    };
  }

  RoomModel copyWith({
    String? roomId,
    String? hostId,
    String? title,
    RoomStatus? status,
    String? missionCategory,
    DateTime? gameStartTime,
    DateTime? gameEndTime,
    DateTime? createdAt,
    UserModel? hostProfile,
  }) {
    return RoomModel(
      roomId: roomId ?? this.roomId,
      hostId: hostId ?? this.hostId,
      title: title ?? this.title,
      status: status ?? this.status,
      missionCategory: missionCategory ?? this.missionCategory,
      gameStartTime: gameStartTime ?? this.gameStartTime,
      gameEndTime: gameEndTime ?? this.gameEndTime,
      createdAt: createdAt ?? this.createdAt,
      hostProfile: hostProfile ?? this.hostProfile,
    );
  }
}
