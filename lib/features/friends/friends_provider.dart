import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features/error/error_provider.dart';
import 'package:manito/features/friends/friends.dart';
import 'package:manito/features/friends/friends_service.dart';
import 'package:manito/features/profiles/profile_provider.dart';
import 'package:manito/features/snackbar/snackbar.dart';
import 'package:manito/features/snackbar/snackbar_provider.dart';

// ========== Service Provider ==========
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

// ========== Notifier Provider ==========
final friendSearchProvider =
    AsyncNotifierProvider<FriendSearchNotifier, FriendSearchState>(
      FriendSearchNotifier.new,
    );

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
class FriendSearchNotifier extends AsyncNotifier<FriendSearchState> {
  @override
  Future<FriendSearchState> build() async {
    // 초기 상태 (비어있음)
    return const FriendSearchState();
  }

  /// 이메일 검색
  Future<void> searchEmail(String email) async {
    // 로딩 상태
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      try {
        final service = ref.read(friendSearchServiceProvider);
        final profile = await service.searchEmail(email);

        return FriendSearchState(query: email, friendProfile: profile);
      } catch (e) {
        // 에러를 글로벌로 전달
        ref.read(errorProvider.notifier).setError('친구 검색 실패: $e');

        // 검색 실패 시에도 query는 유지
        return FriendSearchState(query: email, friendProfile: null);
      }
    });
  }

  /// 친구 신청 보내기
  Future<String> sendFriendRequest() async {
    final currentState = state.valueOrNull;
    final profile = currentState?.friendProfile;

    if (profile == null) {
      ref.read(errorProvider.notifier).setError('검색된 친구가 없습니다');
      return '';
    }

    try {
      final service = ref.read(friendSearchServiceProvider);
      final result = await service.sendFriendRequest(profile.id);

      // 성공 메시지는 스넥바로 표시
      ref
          .read(snackBarProvider.notifier)
          .show(result, type: SnackBarType.success);

      return result;
    } catch (e) {
      ref.read(errorProvider.notifier).setError('친구 신청 실패: $e');
      return '';
    }
  }

  /// 검색 초기화
  void clear() {
    state = const AsyncValue.data(FriendSearchState());
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
  Future<void> blockFriend(String friendId) async {
    try {
      await _service.blockFriend(_currentUserId, friendId);
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
