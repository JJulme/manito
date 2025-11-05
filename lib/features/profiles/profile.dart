// ==========Model==========
import 'dart:io';

class UserProfile {
  final String id;
  final String email;
  final String nickname;
  final String? statusMessage;
  final String? profileImageUrl;
  final String? autoReply;

  UserProfile({
    required this.id,
    required this.email,
    required this.nickname,
    this.statusMessage,
    this.profileImageUrl,
    this.autoReply,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      statusMessage: json['status_message'] as String,
      profileImageUrl: json['profile_image_url'] as String,
      autoReply: json['auto_reply'] as String,
    );
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? nickname,
    String? statusMessage,
    String? profileImageUrl,
    String? autoReply,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      statusMessage: statusMessage ?? this.statusMessage,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      autoReply: autoReply ?? this.autoReply,
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
class UserProfileState {
  final UserProfile? userProfile;
  final bool isLoading;
  final String? error;

  const UserProfileState({
    this.userProfile,
    required this.isLoading,
    this.error,
  });

  const UserProfileState.initial()
    : userProfile = null,
      isLoading = false,
      error = null;

  UserProfileState copyWith({
    UserProfile? userProfile,
    bool? isLoading,
    String? error,
  }) {
    return UserProfileState(
      userProfile: userProfile ?? this.userProfile,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class FriendProfilesState {
  final List<FriendProfile> friendList;
  final bool isLoading;
  final String? error;

  const FriendProfilesState({
    required this.friendList,
    required this.isLoading,
    this.error,
  });

  const FriendProfilesState.initial()
    : friendList = const [],
      isLoading = false,
      error = null;

  FriendProfilesState copyWith({
    List<FriendProfile>? friendList,
    bool? isLoading,
    String? error,
  }) {
    return FriendProfilesState(
      friendList: friendList ?? this.friendList,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// 사용자의 프로필 이미지 수정 할 때 사용되는 상태
class ProfileEditState {
  final File? selectedImage;
  final String profileImageUrl;
  final bool isLoading;
  final String? error;
  const ProfileEditState({
    this.selectedImage,
    required this.profileImageUrl,
    required this.isLoading,
    this.error,
  });

  bool get hasImage => selectedImage != null || profileImageUrl.isNotEmpty;

  const ProfileEditState.initial()
    : selectedImage = null,
      profileImageUrl = '',
      isLoading = false,
      error = null;

  ProfileEditState copyWith({
    File? selectedImage,
    String? profileImageUrl,
    bool? isLoading,
    String? error,
    bool clearSelectedImage = false,
  }) {
    return ProfileEditState(
      selectedImage:
          clearSelectedImage ? null : (selectedImage ?? this.selectedImage),
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
