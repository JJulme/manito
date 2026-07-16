import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.nickname,
    super.profileImageUrl,
    super.statusMessage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      profileImageUrl: json['profile_image_url'] as String?,
      statusMessage: json['status_message'] as String?,
    );
  }

  // 데이터가 없을 때를 위한 '알 수 없는 사용자' 팩토리
  factory UserModel.unknown(String id) {
    return UserModel(
      id: id,
      nickname: 'unknown',
      profileImageUrl: '',
      statusMessage: '',
    );
  }
}
