import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/features_new/friends/domain/entities/friend_entity.dart';
import 'package:manito/features_new/friends/domain/repositories/repository_provider.dart';

// ========== Provider ==========
final friendListProvider =
    AsyncNotifierProvider<FriendListNotifier, List<FriendProfileEntity>>(() {
      return FriendListNotifier();
    });

// ========== Notifier ==========
class FriendListNotifier extends AsyncNotifier<List<FriendProfileEntity>> {
  @override
  FutureOr<List<FriendProfileEntity>> build() async {
    return ref.watch(friendsRepositoryProvider).getFriends();
  }

  // 새로고침
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// 친구 별명 수정 및 로컬 상태 업데이트
  Future<void> updateNickname(String friendId, String newNickname) async {
    // 1. 리포지토리에 수정 요청
    await ref
        .read(friendsRepositoryProvider)
        .updateFriendNickname(friendId, newNickname);
    // 2. 현재 상태(리스트) 가져오기
    final currentList = state.value ?? [];
    // 3. 리스트에서 해당 친구만 찾아서 새로운 별명이 적용된 객체로 교체 (Immutable하게)
    state = AsyncData(
      currentList.map((friend) {
        if (friend.id == friendId) {
          // 바꿀 것만 적으면 나머지는 기존 값 유지
          return friend.copyWith(friendNickname: newNickname);
        }
        return friend;
      }).toList(),
    );
  }

  // 친구 별명 수정 로컬 상태 업데이트
  void updateLocalNickname(String friendId, String newNickname) {
    if (!state.hasValue) return;

    state = AsyncData(
      state.value!.map((friend) {
        if (friend.id == friendId) {
          return friend.copyWith(friendNickname: newNickname);
        }
        return friend;
      }).toList(),
    );
  }

  // 친구 여부 확인 메서드
  bool isAlreadyFriend(String userId) {
    // 현재 상태가 데이터가 있는 상태인지 확인 후 리스트 검색
    return state.maybeWhen(
      data: (friends) => friends.any((f) => f.id == userId),
      orElse: () => false,
    );
  }
}
