import 'package:flutter/material.dart';
import 'package:manito/features/profiles/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendSearchService {
  final SupabaseClient _supabase;
  FriendSearchService(this._supabase);

  // 이메일로 프로필 검색
  Future<UserProfile?> searchEmail(String email) async {
    try {
      final result =
          await _supabase
              .from('profiles')
              .select()
              .eq('email', email)
              .maybeSingle();

      if (result == null) return null;
      return UserProfile.fromJson(result);
    } catch (e) {
      debugPrint('FriendSearchService.searchEmail Error: $e');
      rethrow;
    }
  }

  // 친구신청 보내기
  Future<String> sendFriendRequest(String receiverId) async {
    final String userId = _supabase.auth.currentUser!.id;
    try {
      final String result = await _supabase.rpc(
        'send_friend_request',
        params: {'sender_id': userId, 'receiver_id': receiverId},
      );
      // request_self, already_friends, request_already_sent, request_sent
      return result;
    } catch (e) {
      debugPrint('FriendSearchService.sendFriendRequest Error: $e');
      rethrow;
    }
  }
}

class FriendRequestService {
  final SupabaseClient _supabase;
  FriendRequestService(this._supabase);

  // 친구 요청 목록 가져오기
  Future<List<UserProfile>> fetchFriendRequest() async {
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
          .order('created_at');
      return data.map((e) => UserProfile.fromJson(e['profiles'])).toList();
    } catch (e) {
      debugPrint('FriendRequestService.fetchFriendRequest Error: $e');
      rethrow;
    }
  }

  /// 친구 수락
  Future<void> acceptFriendRequest(String senderId) async {
    try {
      final receiverId = _supabase.auth.currentUser!.id;
      await _supabase.rpc(
        'accept_friend_request',
        params: {'req_sender_id': senderId, 'req_receiver_id': receiverId},
      );
    } catch (e) {
      debugPrint('FriendRequestService.acceptFriendRequest Error: $e');
      rethrow;
    }
  }

  /// 친구 거절
  Future<void> rejectFriendRequest(String senderId) async {
    try {
      final receiverId = _supabase.auth.currentUser!.id;
      await _supabase.rpc(
        'reject_friend_request',
        params: {'req_sender_id': senderId, 'req_receiver_id': receiverId},
      );
    } catch (e) {
      debugPrint('FriendRequestService.rejectFriendRequest Error: $e');
      rethrow;
    }
  }
}

class BlacklistService {
  final SupabaseClient _supabase;
  BlacklistService(this._supabase);

  /// 차단 목록 가져오기
  Future<List<UserProfile>> fetchBlacklist(String userId) async {
    try {
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

      return data.map((e) => UserProfile.fromJson(e['profiles'])).toList();
    } catch (e) {
      debugPrint('BlacklistService.fetchBlacklist Error: $e');
      rethrow;
    }
  }

  /// 차단 해제
  Future<void> unblackUser({
    required String userId,
    required String blackUserId,
  }) async {
    try {
      await _supabase.from('blacklist').delete().match({
        'user_id': userId,
        'black_user_id': blackUserId,
      });
    } catch (e) {
      debugPrint('unblackUser.unblackUser Error: $e');
      rethrow;
    }
  }

  /// 친구 차단
  Future<void> blockFriend(String userId, String friendId) async {
    try {
      await _supabase.rpc(
        'block_friend',
        params: {'p_user_id': userId, 'p_friend_id': friendId},
      );
    } catch (e) {
      debugPrint('blockFriend Error: $e');
      rethrow;
    }
  }
}

class FriendEditService {
  final SupabaseClient _supabase;
  FriendEditService(this._supabase);

  Future<void> updateFriendName(
    String userId,
    String friendId,
    String name,
  ) async {
    try {
      await _supabase
          .from('friends')
          .update({'friend_nickname': name})
          .eq('friend_id', friendId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('FriendEditService.updateFriendName Error: $e');
      rethrow;
    }
  }
}
