import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
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
    AsyncNotifierProvider.autoDispose<FriendSearchNotifier, FriendSearchState>(
      FriendSearchNotifier.new,
    );

final friendRequestProvider =
    AsyncNotifierProvider<FriendRequestNotifier, FriendRequestState>(
      FriendRequestNotifier.new,
    );

final blacklistProvider =
    AsyncNotifierProvider<BlacklistNotifier, BlacklistState>(
      BlacklistNotifier.new,
    );

final friendEditProvider = AsyncNotifierProvider<FriendEditNotifier, void>(
  FriendEditNotifier.new,
);

// ========== Notifier ==========
// 분리 필요
class FriendSearchNotifier extends AutoDisposeAsyncNotifier<FriendSearchState> {
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
      final service = ref.read(friendSearchServiceProvider);
      final profile = await service.searchEmail(email);
      return FriendSearchState(query: email, friendProfile: profile);
    });
  }

  /// 친구 신청 보내기
  Future<String> sendFriendRequest() async {
    final currentState = state.valueOrNull;
    final profile = currentState?.friendProfile;

    if (profile == null) return '';

    try {
      final service = ref.read(friendSearchServiceProvider);
      final result = await service.sendFriendRequest(profile.id);

      // 성공 메시지는 스넥바로 표시
      ref
          .read(snackBarProvider.notifier)
          .show(result, type: SnackBarType.success);

      return result;
    } catch (e) {
      debugPrint('FriendSearchNotifier.sendFriendRequest Error: $e');
      return '';
    }
  }

  /// 검색 초기화
  void clear() {
    state = const AsyncValue.data(FriendSearchState());
  }
}

class FriendRequestNotifier extends AsyncNotifier<FriendRequestState> {
  @override
  FutureOr<FriendRequestState> build() async {
    try {
      final service = ref.read(friendRequestServiceProvider);
      final requestList = await service.fetchFriendRequest();
      return FriendRequestState(requestUserList: requestList);
    } catch (e) {
      debugPrint('FriendRequestNotifier.build Error: $e');
      return FriendRequestState();
    }
  }

  // 새로고침
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  // 친구 수락
  Future<void> acceptFriendRequest(senderId) async {
    try {
      final service = ref.read(friendRequestServiceProvider);
      await service.acceptFriendRequest(senderId);
      // 신청목록 새로고침
      await refresh();
      // 친구목록 새로고침
      await ref.read(friendProfilesProvider.notifier).refreash();
    } catch (e) {
      debugPrint('FriendRequestNotifier.acceptFriendRequest Error: $e');
      rethrow;
    }
  }

  // 친구 거절
  Future<void> rejectFriendRequest(senderId) async {
    try {
      final service = ref.read(friendRequestServiceProvider);
      await service.rejectFriendRequest(senderId);
      // 신청목록 새로고침
      await refresh();
      // 친구목록 새로고침
      await ref.read(friendProfilesProvider.notifier).refreash();
    } catch (e) {
      debugPrint('FriendRequestNotifier.rejectFriendRequest Error: $e');
      rethrow;
    }
  }
}

class BlacklistNotifier extends AsyncNotifier<BlacklistState> {
  @override
  FutureOr<BlacklistState> build() async {
    try {
      final service = ref.read(blacklistServiceProvider);
      final blackList = await service.fetchBlacklist();
      return BlacklistState(blackList: blackList);
    } catch (e) {
      debugPrint('BlacklistNotifier.build Error: $e');
      return BlacklistState();
    }
  }

  // 새로고침
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  // 친구 차단 - 친구 상세 화면에서 사용
  Future<void> blockFriend(String friendId) async {
    try {
      final service = ref.read(blacklistServiceProvider);
      await service.blockFriend(friendId);
      await ref.read(friendProfilesProvider.notifier).refreash();
    } catch (e) {
      debugPrint('BlacklistNotifier.blockFriend Error: $e');
      rethrow;
    }
  }

  // 차단 해제 - 차단 목록에서 사용
  Future<void> unblockUser(String blackUserId) async {
    try {
      final service = ref.read(blacklistServiceProvider);
      await service.unblackUser(blackUserId);
      await refresh();
    } catch (e) {
      debugPrint('BlacklistNotifier.unblockUser Error: $e');
      rethrow;
    }
  }
}

class FriendEditNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  // 친구 이름 사용자 수정
  Future<void> updateFriendName(String friendId, String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(friendEditServiceProvider);
      // 서버 업데이트
      await service.updateFriendName(friendId, name);
      // 로컬 업데이트
      ref
          .read(friendProfilesProvider.notifier)
          .updateFriendNameInList(friendId, name);
    });
  }
}
