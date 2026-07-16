import 'package:manito/features_new/friends/domain/entities/friend_entity.dart';
import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';

abstract class FriendsRepository {
  // 1. 친구 검색 및 요청
  Future<UserEntity?> searchUserByEmail(String email);
  Future<String> sendFriendRequest(String receiverId);

  // 2. 받은 요청 관리
  Future<List<UserEntity>> getReceivedRequests();
  Future<void> acceptFriendRequest(String senderId);
  Future<void> rejectFriendRequest(String senderId);

  // 3. 차단 관리 (Blacklist)
  Future<List<UserEntity>> getBlockedUsers();
  Future<void> blockUser(String friendId);
  Future<void> unblockUser(String userId);

  // 4. 친구 목록 조회 및 관리
  Future<List<FriendProfileEntity>> getFriends();
  Future<void> updateFriendNickname(String friendId, String nickname);
}
