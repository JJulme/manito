// 모든 사용자의 최소 공통 정보
class UserEntity {
  final String id;
  final String nickname;
  final String? profileImageUrl;
  final String? statusMessage;

  UserEntity({
    required this.id,
    required this.nickname,
    this.profileImageUrl,
    this.statusMessage,
  });

  String get displayName => nickname;
}

// '나'의 프로필
class MyProfileEntity extends UserEntity {
  final String email;
  final String? autoReply;
  MyProfileEntity({
    required super.id,
    required super.nickname,
    required this.email,
    this.autoReply,
    super.profileImageUrl,
    super.statusMessage,
  });

  // 나만 체크하는 로직
  bool get isProfileComplete {
    return profileImageUrl != null && profileImageUrl!.isNotEmpty &&
        nickname.isNotEmpty &&
        statusMessage != null && statusMessage!.isNotEmpty &&
        autoReply != null && autoReply!.isNotEmpty;
  }
}

// // '친구'의 프로필
// class FriendProfileEntity extends UserEntity {
//   final String? friendNickname;
//   final int progressMissions;
//   FriendProfileEntity({
//     required super.id,
//     required super.nickname,
//     super.profileImageUrl,
//     super.statusMessage,
//     this.friendNickname,
//     this.progressMissions = 0,
//   });

//   String get displayName => friendNickname ?? nickname;

//   FriendProfileEntity copyWith({
//     String? id,
//     String? nickname,
//     String? profileImageUrl,
//     String? statusMessage,
//     String? friendNickname,
//     int? progressMissions,
//   }) {
//     return FriendProfileEntity(
//       id: id ?? this.id,
//       nickname: nickname ?? this.nickname,
//       profileImageUrl: profileImageUrl ?? this.profileImageUrl,
//       statusMessage: statusMessage ?? this.statusMessage,
//       friendNickname: friendNickname ?? this.friendNickname,
//       progressMissions: progressMissions ?? this.progressMissions,
//     );
//   }
// }
