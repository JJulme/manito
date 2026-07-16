// '친구'의 프로필
import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';

class FriendProfileEntity extends UserEntity {
  final String? friendNickname;
  final int progressMissions;
  FriendProfileEntity({
    required super.id,
    required super.nickname,
    super.profileImageUrl,
    super.statusMessage,
    this.friendNickname,
    this.progressMissions = 0,
  });

  @override
  String get displayName => friendNickname ?? nickname;

  FriendProfileEntity copyWith({
    String? id,
    String? nickname,
    String? profileImageUrl,
    String? statusMessage,
    String? friendNickname,
    int? progressMissions,
  }) {
    return FriendProfileEntity(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      statusMessage: statusMessage ?? this.statusMessage,
      friendNickname: friendNickname ?? this.friendNickname,
      progressMissions: progressMissions ?? this.progressMissions,
    );
  }
}
