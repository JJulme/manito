import 'package:manito/features_new/friends/domain/entities/friend_entity.dart';

class FriendProfileModel extends FriendProfileEntity {
  FriendProfileModel({
    required super.id,
    required super.nickname,
    super.profileImageUrl,
    super.statusMessage,
    super.friendNickname,
    super.progressMissions,
  });

  factory FriendProfileModel.fromJson(
    Map<String, dynamic> json, {
    int missionCount = 0,
  }) {
    final profileJson = json['profiles'] as Map<String, dynamic>;
    return FriendProfileModel(
      id: profileJson['id'],
      nickname: profileJson['nickname'],
      profileImageUrl: profileJson['profile_image_url'],
      statusMessage: profileJson['status_message'],
      friendNickname: json['friend_nickname'],
      progressMissions: missionCount,
    );
  }
}
