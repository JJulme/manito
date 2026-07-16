// ==========Model==========
import 'dart:io';

class MyProfile {
  final String id;
  final String email;
  final String nickname;
  final String? statusMessage;
  final String? profileImageUrl;
  final String? autoReply;

  MyProfile({
    required this.id,
    required this.email,
    required this.nickname,
    this.statusMessage,
    this.profileImageUrl,
    this.autoReply,
  });

  bool get isProfileComplete {
    return profileImageUrl!.isNotEmpty &&
        nickname.isNotEmpty &&
        statusMessage!.isNotEmpty &&
        autoReply!.isNotEmpty;
  }

  factory MyProfile.fromJson(Map<String, dynamic> json) {
    return MyProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      statusMessage: json['status_message'] as String,
      profileImageUrl: json['profile_image_url'] as String,
      autoReply:
          json['auto_reply'] != null ? json['auto_reply'] as String : null,
    );
  }
}

class UserProfile {
  final String id;
  final String nickname;
  final String? statusMessage;
  final String? profileImageUrl;
  final String? friendNickname;
  final bool isUnknown;

  UserProfile({
    required this.id,
    required this.nickname,
    this.statusMessage,
    this.profileImageUrl,
    this.friendNickname,
    this.isUnknown = false,
  });
  String get displayName {
    return friendNickname?.isNotEmpty == true ? friendNickname! : nickname;
  }

  // '알 수 없는 사용자' 상태를 표현하는 팩토리 생성자
  factory UserProfile.unknown(String unknownId) {
    return UserProfile(
      id: unknownId,
      nickname: 'unknown',
      profileImageUrl: '', // 기본 아바타
      isUnknown: true,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      statusMessage: json['status_message'] as String,
      profileImageUrl: json['profile_image_url'] as String,
    );
  }
}

class FriendProfile {
  final String id;
  final String nickname;
  final String? statusMessage;
  final String? profileImageUrl;
  final String? friendNickname;
  int progressMissions;

  FriendProfile({
    required this.id,
    required this.nickname,
    this.statusMessage,
    this.profileImageUrl,
    this.friendNickname,
    this.progressMissions = 0,
  });

  String get displayName {
    return friendNickname?.isNotEmpty == true ? friendNickname! : nickname;
  }

  factory FriendProfile.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> profileJson = json['profiles'];
    return FriendProfile(
      id: profileJson['id'] as String,
      nickname: profileJson['nickname'] as String,
      statusMessage: profileJson['status_message'] as String?,
      profileImageUrl: profileJson['profile_image_url'] as String?,
      friendNickname: json['friend_nickname'] as String?,
      progressMissions: 0,
    );
  }

  FriendProfile copyWith({
    String? id,
    String? nickname,
    String? statusMessage,
    String? profileImageUrl,
    String? friendNickname,
    int? progressMissions,
  }) {
    return FriendProfile(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      statusMessage: statusMessage ?? this.statusMessage,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      friendNickname: friendNickname ?? this.friendNickname,
      progressMissions: progressMissions ?? this.progressMissions,
    );
  }
}

// ==========Status==========
// class MyProfileState {
//   final MyProfile? myProfile;

//   const MyProfileState({this.myProfile});

//   bool get isProfileComplete {
//     if (myProfile == null) return false;
//     return myProfile!.profileImageUrl!.isNotEmpty &&
//         myProfile!.nickname.isNotEmpty &&
//         myProfile!.statusMessage!.isNotEmpty &&
//         myProfile!.autoReply!.isNotEmpty;
//   }

//   MyProfileState copyWith({MyProfile? myProfile}) {
//     return MyProfileState(myProfile: myProfile ?? this.myProfile);
//   }
// }

// class UserProfileState {
//   final UserProfile? userProfile;

//   const UserProfileState({this.userProfile});

//   bool get isProfileComplete {
//     if (userProfile == null) return false;
//     return userProfile!.profileImageUrl!.isNotEmpty &&
//         userProfile!.nickname.isNotEmpty &&
//         userProfile!.statusMessage!.isNotEmpty &&
//         userProfile!.autoReply!.isNotEmpty;
//   }
// }

class FriendProfilesState {
  final List<FriendProfile> friendList;
  final Map<String, FriendProfile> friendListMap;

  FriendProfilesState({
    this.friendList = const [],
    Map<String, FriendProfile>? friendListMap,
  }) : friendListMap = {for (var f in friendList) f.id: f};

  FriendProfilesState copyWith({List<FriendProfile>? friendList}) {
    final newFriendList = friendList ?? this.friendList;
    return FriendProfilesState(
      friendList: newFriendList,
      friendListMap: {for (var f in newFriendList) f.id: f},
    );
  }
}

class ProfileImageState {
  final File? selectedImage;
  final String profileImageUrl;
  const ProfileImageState({this.selectedImage, this.profileImageUrl = ''});

  ProfileImageState copyWith({File? selectedImage, String? profileImageUrl}) {
    return ProfileImageState(
      selectedImage: selectedImage ?? this.selectedImage,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}

class ProfileEditState {
  final String nickname;
  final String statusMessage;
  final String autoReply;

  const ProfileEditState({
    this.nickname = '',
    this.statusMessage = '',
    this.autoReply = '',
  });

  ProfileEditState copyWith({
    String? nickname,
    String? statusMessage,
    String? autoReply,
  }) {
    return ProfileEditState(
      nickname: nickname ?? this.nickname,
      statusMessage: statusMessage ?? this.statusMessage,
      autoReply: autoReply ?? this.autoReply,
    );
  }
}
