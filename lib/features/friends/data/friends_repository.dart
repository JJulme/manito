import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/util/app_logger.dart';

class FriendsRepository {
  final SupabaseClient _supabase;

  FriendsRepository(this._supabase);

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Search user by 8-digit unique code
  Future<UserModel?> searchUserByCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.length != 8) return null;

    try {
      AppLogger.d('Searching user by code: $cleanCode', tag: 'FRIENDS');
      final response = await _supabase
          .from('users')
          .select()
          .eq('unique_code', cleanCode)
          .maybeSingle();

      if (response == null) {
        AppLogger.d('No user found for code: $cleanCode', tag: 'FRIENDS');
        return null;
      }
      return UserModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('searchUserByCode Error: $e', tag: 'FRIENDS', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Get friendship status between current user and target user
  Future<FriendshipModel?> getFriendship(String targetUserId) async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final response = await _supabase
          .from('friendships')
          .select('*, requester:users!requester_id(*), receiver:users!receiver_id(*)')
          .or('and(requester_id.eq.$uid,receiver_id.eq.$targetUserId),and(requester_id.eq.$targetUserId,receiver_id.eq.$uid)')
          .maybeSingle();

      if (response == null) return null;
      return FriendshipModel.fromJson(response, currentUserId: uid);
    } catch (e, s) {
      AppLogger.e('getFriendship Error: $e', tag: 'FRIENDS', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Send friend request
  Future<void> sendFriendRequest(String receiverId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('로그인이 필요합니다.');
    if (uid == receiverId) throw Exception('자기 자신에게는 친구 요청을 보낼 수 없습니다.');

    try {
      AppLogger.i('Sending friend request to: $receiverId', tag: 'FRIENDS');
      await _supabase.from('friendships').insert({
        'requester_id': uid,
        'receiver_id': receiverId,
        'status': 'REQUESTED',
      });
      AppLogger.i('Friend request sent successfully', tag: 'FRIENDS');
    } catch (e, s) {
      AppLogger.e('sendFriendRequest Error: $e', tag: 'FRIENDS', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(int friendshipId) async {
    try {
      AppLogger.i('Accepting friend request: $friendshipId', tag: 'FRIENDS');
      await _supabase.from('friendships').update({
        'status': 'ACCEPTED',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('friendship_id', friendshipId);
      AppLogger.i('Friend request accepted', tag: 'FRIENDS');
    } catch (e, s) {
      AppLogger.e('acceptFriendRequest Error: $e', tag: 'FRIENDS', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Reject / Cancel friend request
  Future<void> rejectFriendRequest(int friendshipId) async {
    return deleteFriendship(friendshipId);
  }

  /// Delete friendship
  Future<void> deleteFriendship(int friendshipId) async {
    try {
      AppLogger.i('Deleting friendship: $friendshipId', tag: 'FRIENDS');
      await _supabase.from('friendships').delete().eq('friendship_id', friendshipId);
    } catch (e, s) {
      AppLogger.e('deleteFriendship Error: $e', tag: 'FRIENDS', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Fetch accepted friends list
  Future<List<FriendshipModel>> fetchAcceptedFriends() async {
    final uid = currentUserId;
    if (uid == null) return [];

    try {
      final response = await _supabase
          .from('friendships')
          .select('*, requester:users!requester_id(*), receiver:users!receiver_id(*)')
          .eq('status', 'ACCEPTED')
          .or('requester_id.eq.$uid,receiver_id.eq.$uid');

      return (response as List)
          .map((json) => FriendshipModel.fromJson(json, currentUserId: uid))
          .toList();
    } catch (e, s) {
      AppLogger.e('fetchAcceptedFriends Error: $e', tag: 'FRIENDS', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Fetch incoming/received friend requests
  Future<List<FriendshipModel>> fetchReceivedRequests() async {
    final uid = currentUserId;
    if (uid == null) return [];

    try {
      final response = await _supabase
          .from('friendships')
          .select('*, requester:users!requester_id(*), receiver:users!receiver_id(*)')
          .eq('receiver_id', uid)
          .eq('status', 'REQUESTED');

      return (response as List)
          .map((json) => FriendshipModel.fromJson(json, currentUserId: uid))
          .toList();
    } catch (e, s) {
      AppLogger.e('fetchReceivedRequests Error: $e', tag: 'FRIENDS', error: e, stackTrace: s);
      rethrow;
    }
  }
}
