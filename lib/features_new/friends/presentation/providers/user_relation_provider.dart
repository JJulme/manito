import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/features_new/friends/domain/repositories/repository_provider.dart';
import 'package:manito/features_new/friends/presentation/providers/friend_list_provider.dart';
import 'package:manito/features_new/profile/presentation/providers/user_profile_provider.dart';

// ========== Provider ==========
final userRelationProvider =
    AsyncNotifierProvider.autoDispose<UserRelationNotifier, void>(() {
      return UserRelationNotifier();
    });

// ========== Notifier ==========
class UserRelationNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  // 친구 닉네임 수정
  Future<void> updateNickname(String friendId, String newNickname) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // 1. 서버 DB 수정 (리포지토리 호출)
      await ref
          .read(friendsRepositoryProvider)
          .updateFriendNickname(friendId, newNickname);
      // 2. 로컬 상태 업데이트 (네트워크 다시 타지 않고 메모리 즉시 수정)
      ref
          .read(friendListProvider.notifier)
          .updateLocalNickname(friendId, newNickname);
      // 3. 현재 보고 있는 상세 프로필 정보도 무효화 (상세 화면 대응)
      ref.invalidate(userProfileProvider(friendId));

      return null;
    });
  }

  // 유저 차단
  Future<void> blockUser(String userId) async {
    // 상태를 로딩으로 변경
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(friendsRepositoryProvider);
      await repository.blockUser(userId);
      // 친구 목록 새로고침
      ref.invalidate(friendListProvider);
      return;
    });
  }
}
