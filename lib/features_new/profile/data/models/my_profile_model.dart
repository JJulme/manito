import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';

class MyProfileModel extends MyProfileEntity {
  MyProfileModel({
    required super.id,
    required super.nickname,
    required super.email,
    super.autoReply,
    super.profileImageUrl,
    super.statusMessage,
  });

  // 서버 데이터를 엔티티로 변환하는 '공장' 역할
  factory MyProfileModel.fromJson(Map<String, dynamic> json) {
    return MyProfileModel(
      id: json['id'],
      nickname: json['nickname'],
      email: json['email'],
      autoReply: json['auto_reply'],
      profileImageUrl: json['profile_image_url'],
      statusMessage: json['status_message'],
    );
  }
}
