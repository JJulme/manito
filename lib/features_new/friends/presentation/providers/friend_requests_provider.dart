import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/utils/logger.dart';
import 'package:manito/features_new/friends/domain/repositories/repository_provider.dart';
import 'package:manito/features_new/friends/presentation/providers/friend_list_provider.dart';
import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';

// ========== Provider ==========
final friendRequestsProvider =
    AsyncNotifierProvider.autoDispose<FriendRequestsNotifier, List<UserEntity>>(
      () {
        return FriendRequestsNotifier();
      },
    );

// ========== Notifier ==========
class FriendRequestsNotifier
    extends AutoDisposeAsyncNotifier<List<UserEntity>> {
  @override
  FutureOr<List<UserEntity>> build() {
    return ref.read(friendsRepositoryProvider).getReceivedRequests();
  }

  // 새로고침
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  // 1. 친구 요청 수락
  Future<void> acceptRequest(String senderId) async {
    try {
      await ref.read(friendsRepositoryProvider).acceptFriendRequest(senderId);
      // 성공 시: 로컬 상태에서 해당 유저 삭제 (UI 즉시 반영)
      final currentRequests = state.value ?? [];
      state = AsyncData(
        currentRequests.where((user) => user.id != senderId).toList(),
      );
      ref.invalidate(friendListProvider);
    } catch (e) {
      Log.e('$e');
      rethrow;
    }
  }

  // 2. 친구 요청 거절
  Future<void> rejectRequest(String senderId) async {
    try {
      await ref.read(friendsRepositoryProvider).rejectFriendRequest(senderId);
      // 성공 시: 로컬 상태에서 해당 유저 삭제 (UI 즉시 반영)
      final currentRequests = state.value ?? [];
      state = AsyncData(
        currentRequests.where((user) => user.id != senderId).toList(),
      );
    } catch (e) {
      Log.e('$e');
      rethrow;
    }
  }
}
