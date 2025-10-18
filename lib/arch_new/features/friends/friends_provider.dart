import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/arch_new/core/providers.dart';
import 'package:manito/arch_new/features/friends/friends.dart';
import 'package:manito/arch_new/features/friends/friends_service.dart';
import 'package:manito/arch_new/features/profiles/profile_provider.dart';

// ========== Provider ==========
final friendSearchServiceProvider = Provider<FriendSearchService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return FriendSearchService(supabase);
});

final friendRequestServiceProvider = Provider<FriendRequestService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return FriendRequestService(supabase);
});

final blacklistServiceProvider = Provider<BlacklistService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return BlacklistService(supabase);
});

final friendEditServiceProvider = Provider<FriendEditService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return FriendEditService(supabase);
});

final friendSearchProvider =
    StateNotifierProvider.autoDispose<FriendSearchNotifier, FriendSearchState>((
      ref,
    ) {
      final service = ref.watch(friendSearchServiceProvider);
      return FriendSearchNotifier(service);
    });

final friendRequestProvider = StateNotifierProvider.autoDispose<
  FriendRequestNotifier,
  FriendRequestState
>((ref) {
  final service = ref.watch(friendRequestServiceProvider);
  return FriendRequestNotifier(ref, service);
});

final blacklistProvider =
    StateNotifierProvider.autoDispose<BlacklistNotifier, BlacklistState>((ref) {
      final service = ref.watch(blacklistServiceProvider);
      return BlacklistNotifier(ref, service);
    });

final friendEditProvider =
    StateNotifierProvider.autoDispose<FriendEditNotifier, FriendEditState>((
      ref,
    ) {
      final service = ref.watch(friendEditServiceProvider);
      return FriendEditNotifier(ref, service);
    });

// ========== Notifier ==========
class FriendSearchNotifier extends StateNotifier<FriendSearchState> {
  final FriendSearchService _service;
  FriendSearchNotifier(this._service) : super(const FriendSearchState());

  // 이메일 검색
  Future<void> searchEmail(String email) async {
    state = state.copyWith(isLoading: true, query: email, friendProfile: null);
    try {
      final profile = await _service.searchEmail(email);
      state = state.copyWith(
        isLoading: false,
        isSearching: true,
        friendProfile: profile,
      );
    } catch (e) {
      debugPrint('FriendSearchNotifier.searchEmail Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // 친구 신청 보내기
  Future<String> sendFriendRequest() async {
    final profile = state.friendProfile;
    if (profile == null) return '';
    final result = await _service.sendFriendRequest(profile.id);
    state = state.copyWith(message: result);
    return result;
  }
}

class FriendRequestNotifier extends StateNotifier<FriendRequestState> {
  final Ref _ref;
  final FriendRequestService _service;
  FriendRequestNotifier(this._ref, this._service)
    : super(FriendRequestState()) {
    fetchFriendRequest();
  }

  String get _currentUserId => _ref.read(currentUserProvider)!.id;

  // 친구요청 가져오기
  Future<void> fetchFriendRequest() async {
    state = state.copyWith(isLoading: true);
    try {
      final requestList = await _service.fetchFriendRequest(_currentUserId);
      state = state.copyWith(requestUserList: requestList, isLoading: false);
    } catch (e) {
      debugPrint('FriendRequestNotifier.fetchFriendRequest Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 친구 수락
  Future<String> acceptFriendRequest(String senderId) async {
    try {
      await _service.acceptFriendRequest(
        senderId: senderId,
        receiverId: _currentUserId,
      );

      await fetchFriendRequest();
      await _ref.read(friendProfilesProvider.notifier).fetchFriendList();
      return 'request_accept';
    } catch (e) {
      debugPrint('FriendRequestNotifier.acceptFriendRequest Error: $e');
      return 'request_accept_error';
    }
  }

  /// 친구 거절
  Future<String> rejectFriendRequest(String senderId) async {
    try {
      await _service.rejectFriendRequest(
        senderId: senderId,
        receiverId: _currentUserId,
      );

      await fetchFriendRequest();
      return 'request_reject';
    } catch (e) {
      debugPrint('FriendRequestNotifier.rejectFriendRequest Error: $e');
      return 'request_reject_error';
    }
  }
}

class BlacklistNotifier extends StateNotifier<BlacklistState> {
  final Ref _ref;
  final BlacklistService _service;

  BlacklistNotifier(this._ref, this._service) : super(BlacklistState()) {
    fetchBlacklist();
  }

  String get _currentUserId => _ref.read(currentUserProvider)!.id;

  /// 차단 목록 가져오기
  Future<void> fetchBlacklist() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final blackList = await _service.fetchBlacklist(_currentUserId);
      state = state.copyWith(blackList: blackList, isLoading: false);
    } catch (e) {
      debugPrint('BlacklistNotifier.fetchBlacklist Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 차단 해제
  Future<String> unblackUser(String blackUserId) async {
    try {
      await _service.unblackUser(
        userId: _currentUserId,
        blackUserId: blackUserId,
      );
      // 목록에서 제거 (UI 즉시 업데이트)
      state = state.copyWith(
        blackList:
            state.blackList.where((user) => user.id != blackUserId).toList(),
      );
      return 'unblack_success';
    } catch (e) {
      debugPrint('BlacklistNotifier.unblackUser Error: $e');
      return 'unblack_error';
    }
  }

  /// 친구 차단
  Future<bool> blockFriend(String friendId) async {
    try {
      final result = await _service.blockFriend(_currentUserId, friendId);
      return result;
    } catch (e) {
      debugPrint('BlacklistNotifier.blockFriend Error: $e');
      rethrow;
    }
  }
}

class FriendEditNotifier extends StateNotifier<FriendEditState> {
  final Ref _ref;
  final FriendEditService _service;
  FriendEditNotifier(this._ref, this._service) : super(FriendEditState());

  String get _currentUserId => _ref.read(currentUserProvider)!.id;

  Future<bool> updateFriendName(String friendId, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateFriendName(_currentUserId, friendId, name);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      debugPrint('FriendEditNotifier.updateFriendName Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
