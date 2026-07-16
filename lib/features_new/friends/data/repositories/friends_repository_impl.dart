import 'package:cached_network_image/cached_network_image.dart';
import 'package:manito/core/utils/logger.dart';
import 'package:manito/features_new/friends/data/models/friend_profile_model.dart';
import 'package:manito/features_new/friends/domain/entities/friend_entity.dart';
import 'package:manito/features_new/friends/domain/repositories/friends_repository.dart';
import 'package:manito/features_new/profile/data/models/user_model.dart';
import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsRepositoryImpl implements FriendsRepository {
  final SupabaseClient _supabase;
  FriendsRepositoryImpl(this._supabase);

  // ========== 1. 친구 검색 및 요청 ==========
  // 친구 이메일 검색
  @override
  Future<UserEntity?> searchUserByEmail(String email) async {
    try {
      final myId = _supabase.auth.currentUser!.id;
      final data =
          await _supabase
              .from('profiles')
              .select()
              .eq('email', email)
              .neq('id', myId)
              .maybeSingle();

      if (data == null) return null;
      return UserModel.fromJson(data);
    } catch (e) {
      Log.e('$e');
      rethrow;
    }
  }

  // 친구 요청
  @override
  Future<String> sendFriendRequest(String receiverId) async {
    try {
      final String userId = _supabase.auth.currentUser!.id;
      final String data = await _supabase.rpc(
        'send_friend_request',
        params: {'sender_id': userId, 'receiver_id': receiverId},
      );
      // already_friends, request_already_sent, request_sent
      return data;
    } catch (e) {
      Log.e('$e');
      rethrow;
    }
  }

  // ========== 2. 받은 요청 관리 ==========
  // 친구 요청 목록 가져오기
  @override
  Future<List<UserEntity>> getReceivedRequests() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('friend_requests')
          .select('''
            profiles!friend_requests_sender_id_fkey(
              id,
              email,
              nickname,
              status_message,
              profile_image_url
            )
          ''')
          .eq('receiver_id', userId)
          .order('created_at', ascending: false);
      return (data as List).map((e) {
        final profileData = e['profiles'];
        return UserModel.fromJson(profileData as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      Log.e('$e');
      rethrow;
    }
  }

  // 친구 요청 수락
  @override
  Future<void> acceptFriendRequest(String senderId) async {
    try {
      final receiverId = _supabase.auth.currentUser!.id;
      await _supabase.rpc(
        'accept_friend_request',
        params: {'req_sender_id': senderId, 'req_receiver_id': receiverId},
      );
    } catch (e) {
      Log.e('$e');
      rethrow;
    }
  }

  // 친구 요청 거절
  @override
  Future<void> rejectFriendRequest(String senderId) async {
    try {
      final receiverId = _supabase.auth.currentUser!.id;
      await _supabase.rpc(
        'reject_friend_request',
        params: {'req_sender_id': senderId, 'req_receiver_id': receiverId},
      );
    } catch (e) {
      Log.e('$e');
      rethrow;
    }
  }

  // ========== 3. 차단 관리 ==========
  // 차단 목록 가져오기
  @override
  Future<List<UserEntity>> getBlockedUsers() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('blacklist')
          .select('''
            profiles!blacklist_black_user_id_fkey(
              id,
              email,
              nickname,
              status_message,
              profile_image_url
            )
          ''')
          .eq('user_id', userId)
          .order('created_at');

      return (data as List)
          .where((e) => e['profiles'] != null) // 탈퇴한 유저 등 예외 처리
          .map((e) => UserModel.fromJson(e['profiles'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Log.e('$e');
      rethrow;
    }
  }

  // 친구 차단
  @override
  Future<void> blockUser(String friendId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.rpc(
        'block_friend',
        params: {'p_user_id': userId, 'p_friend_id': friendId},
      );
    } catch (e) {
      Log.e('$e');
      rethrow;
    }
  }

  // 차단 해제
  @override
  Future<void> unblockUser(String blackUserId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('blacklist').delete().match({
        'user_id': userId,
        'black_user_id': blackUserId,
      });
    } catch (e) {
      Log.e('$e');
      rethrow;
    }
  }

  // ========== 4. 친구 목록 조회 및 관리 ==========
  // 친구들 프로필 가져오기
  @override
  Future<List<FriendProfileEntity>> getFriends() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      // 1. Supabase에서 친구 기본 데이터 및 프로필 Join해서 가져오기
      final data = await _supabase
          .from('friends')
          .select('''
            friend_nickname,
            profiles!friends_friend_id_fkey(
              id,
              nickname,
              status_message,
              profile_image_url
            )
          ''')
          .eq('user_id', userId);
      if ((data as List).isEmpty) return [];

      final List<Map<String, dynamic>> friendsData =
          List<Map<String, dynamic>>.from(data);

      // 2. 친구들의 미션 개수 정보 가져오기 (데이터 로직 분리)
      final friendIds =
          friendsData.map((e) => e['profiles']['id'] as String).toList();
      final missionCounts = await _fetchMissionCounts(friendIds);

      // 3. Model을 거쳐 최종 Entity 리스트로 변환
      final List<FriendProfileEntity> friendList =
          friendsData.map((json) {
            final String friendId = json['profiles']['id'];
            final int count = missionCounts[friendId] ?? 0;

            // Model의 factory 생성자를 사용하여 Entity 생성
            return FriendProfileModel.fromJson(json, missionCount: count);
          }).toList();

      // 4. 비즈니스 로직: 이름순 정렬
      friendList.sort((a, b) => a.displayName.compareTo(b.displayName));

      // 5. 부수 효과: 이미지 캐시 비우기 (필요 시)
      _evictProfileImageCache(friendList);

      return friendList;
    } catch (e) {
      Log.e('$e');
      rethrow;
    }
  }

  // 친구 미션 카운트 가져오기 - getFriends()
  Future<Map<String, int>> _fetchMissionCounts(List<String> friendIds) async {
    if (friendIds.isEmpty) return {};
    final data = await _supabase
        .from('missions')
        .select('creator_id')
        .neq('status', 'complete')
        .inFilter('creator_id', friendIds);
    Map<String, int> counts = {};
    for (var item in data) {
      final String creatorId = item['creator_id'];
      counts[creatorId] = (counts[creatorId] ?? 0) + 1;
    }
    return counts;
  }

  // 캐시 관리 - getFriends()
  void _evictProfileImageCache(List<FriendProfileEntity> friends) {
    for (var friend in friends) {
      if (friend.profileImageUrl != null &&
          friend.profileImageUrl!.isNotEmpty) {
        CachedNetworkImage.evictFromCache(friend.profileImageUrl!);
      }
    }
  }

  // 친구 별명 설정
  @override
  Future<void> updateFriendNickname(String friendId, String nickname) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase
          .from('friends')
          .update({'friend_nickname': nickname})
          .eq('friend_id', friendId)
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }
}

class FriendRequestStatus {
  static const sent = 'request_sent';
  static const alreadyFriends = 'already_friends';
  static const alreadySent = 'request_already_sent';
}
