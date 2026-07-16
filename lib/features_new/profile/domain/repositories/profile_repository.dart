import 'dart:io';
import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';

abstract class ProfileRepository {
  Future<MyProfileEntity> getMyProfile();
  Future<MyProfileEntity> updateMyProfile({
    required String nickname,
    required String statusMessage,
    required String autoReply,
    File? imageFile,
    String? existingImageUrl,
  });
  // Future<List<FriendProfileEntity>> getFriends();
  // Future<void> updateFriendNickname(String friendId, String nickname);
  Future<UserEntity> getUserProfile(String unknownId);
}
