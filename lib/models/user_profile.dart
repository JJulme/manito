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
    return FriendProfile(
      friendNickname: json['friend_nickname'] as String?,
      id: profileJson?['id'] as String?,
      nickname: profileJson?['nickname'] as String?,
      statusMessage: profileJson?['status_message'] as String?,
      profileImageUrl: profileJson?['profile_image_url'] as String?,
    );
  }
}
