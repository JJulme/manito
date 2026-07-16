import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/utils/logger.dart';
import 'package:manito/features_new/friends/domain/repositories/repository_provider.dart';
import 'package:manito/features_new/friends/presentation/providers/friend_list_provider.dart';
import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';

// ========== Provider ==========
final blockedUsersProvider =
    AsyncNotifierProvider.autoDispose<BlockedUsersNotifier, List<UserEntity>>(
      () {
        return BlockedUsersNotifier();
      },
    );

// ========== Notifier ==========
class BlockedUsersNotifier extends AutoDisposeAsyncNotifier<List<UserEntity>> {
  @override
  FutureOr<List<UserEntity>> build() {
    return ref.read(friendsRepositoryProvider).getBlockedUsers();
  }

  // 새로고침
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  // 1. 유저 차단하기
  Future<void> blockUser(UserEntity userId) async {
    try {
      // 서버 DB에 차단 기록 추가
      await ref.read(friendsRepositoryProvider).blockUser(userId.id);
      // (중요) 내 친구 목록에서도 이 유저를 즉시 없애기 위해 친구 목록 새로고침
      ref.invalidate(friendListProvider);

      // 내 차단 목록 상태 업데이트 (이미 로드된 데이터가 있다면 새 유저 추가)
      final currentList = state.value ?? [];
      state = AsyncData([...currentList, userId]);
    } catch (e) {
      Log.e('$e');
      rethrow;
    }
  }

  // 차단 해제
  Future<void> unblock(String userId) async {
    try {
      await ref.read(friendsRepositoryProvider).unblockUser(userId);
      final currentState = state.value ?? [];
      state = AsyncData(
        currentState.where((user) => user.id != userId).toList(),
      );
    } catch (e) {
      Log.e('$e');
      rethrow;
    }
  }
}
