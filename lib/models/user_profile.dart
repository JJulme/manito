class UserProfile {
  String id;
  String email;
  String nickname;
  String statusMessage;
  String? profileImageUrl;

  UserProfile({
    this.id = '',
    this.email = '',
    this.nickname = '',
    this.statusMessage = '',
    this.profileImageUrl,
  });

  // 프로필 데이터 가져올 때
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'] ?? '',
      nickname: json['nickname'],
      statusMessage: json['status_message'] ?? '',
      profileImageUrl: json['profile_image_url'],
    );
  }

  // 프로필 데이터 수정할 때 - 검토 필요
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'status_message': statusMessage,
      'profile_image_url': profileImageUrl,
    };
  }
}

class FriendProfile {
  final String? friendNickname;
  final String? id;
  final String? nickname;
  final String? statusMessage;
  final String? profileImageUrl;

  FriendProfile({
    this.friendNickname,
    this.id,
    this.nickname,
    this.statusMessage,
    this.profileImageUrl,
  });

  factory FriendProfile.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? profileJson = json['profiles'];
    // 1. profiles 객체 내의 실제 닉네임을 먼저 가져옵니다.
    final String? actualNickname = profileJson?['nickname'] as String?;
    // 2. friend_nickname 값을 가져옵니다.
    final String? rawFriendNickname = json['friend_nickname'] as String?;
    // 3. rawFriendNickname이 유효한지(null이 아니고, 비어있지 않으며, 공백만으로 이루어지지 않았는지) 확인합니다.
    final bool isFriendNicknameValid =
        rawFriendNickname != null && rawFriendNickname.trim().isNotEmpty;
    return FriendProfile(
      id: profileJson?['id'] as String?,
      nickname: isFriendNicknameValid ? rawFriendNickname : actualNickname,
      statusMessage: profileJson?['status_message'] as String?,
      profileImageUrl: profileJson?['profile_image_url'] as String?,
    );
  }
}
