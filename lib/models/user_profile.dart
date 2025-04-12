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
