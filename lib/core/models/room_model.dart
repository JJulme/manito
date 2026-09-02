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
      roomId: json['room_id']?.toString() ?? '',
      hostId: json['host_id']?.toString() ?? '',
      title: json['title'] as String? ?? '마니또 대기실',
      status: RoomStatus.fromString(json['status']?.toString() ?? ''),
      missionCategory: json['mission_category'] as String?,
      gameStartTime: _parseUtcToLocal(json['game_start_time']),
      gameEndTime: _parseUtcToLocal(json['game_end_time']),
      createdAt: _parseUtcToLocal(json['created_at']) ?? DateTime.now(),
      hostProfile: json['host'] is Map<String, dynamic>
          ? UserModel.fromJson(json['host'] as Map<String, dynamic>)
          : null,
    );
  }

  static DateTime? _parseUtcToLocal(dynamic val) {
    if (val == null) return null;
    final str = val.toString().trim();
    if (str.isEmpty) return null;
    final parsed = DateTime.tryParse(str);
    if (parsed == null) return null;
    return parsed.isUtc ? parsed.toLocal() : parsed;
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
