import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features/profiles/profile.dart';
import 'package:manito/features/profiles/profile_service.dart';

// ========== Service Provider ==========
final profileServiceProvider = Provider<ProfileService>((ref) {
  final supabase = ref.read(supabaseProvider);
  return ProfileService(supabase);
});

final profileEditServiceProvider = Provider.autoDispose<ProfileEditService>((
  ref,
) {
  final supabase = ref.read(supabaseProvider);
  return ProfileEditService(supabase);
});

// ========== Notifier Provider ==========
final myProfileProvider = AsyncNotifierProvider<MyProfileNotifier, MyProfile>(
  MyProfileNotifier.new,
);

final friendProfilesProvider =
    AsyncNotifierProvider<FriendProfileNotifier, FriendProfilesState>(
      FriendProfileNotifier.new,
    );

final friendDetailProvider = Provider.autoDispose
    .family<FriendProfile?, String>((ref, friendId) {
      return ref.watch(
        friendProfilesProvider.select((async) {
          return async.valueOrNull?.friendListMap[friendId];
        }),
      );
    });

final profileImageProvider =
    NotifierProvider.autoDispose<ProfileImageNotifier, ProfileImageState>(
      ProfileImageNotifier.new,
    );

final profileEditProvider =
    AsyncNotifierProvider.autoDispose<ProfileEditNotifier, ProfileEditState>(
      ProfileEditNotifier.new,
    );

final getProfileProvider =
    AsyncNotifierProvider.family<GetProfileNotifier, UserProfile, String>(
      GetProfileNotifier.new,
    );

final combinedProfileProvider = Provider.family<
  AsyncValue<({UserProfile manito, UserProfile creator})>,
  ({String manitoId, String creatorId})
>((ref, ids) {
  final manitoAsync = ref.watch(getProfileProvider(ids.manitoId));
  final creatorAsync = ref.watch(getProfileProvider(ids.creatorId));

  // 둘 다 로딩 중
  if (manitoAsync.isLoading || creatorAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // 둘 중 하나라도 에러
  if (manitoAsync.hasError) {
    return AsyncValue.error(manitoAsync.error!, manitoAsync.stackTrace!);
  }
  if (creatorAsync.hasError) {
    return AsyncValue.error(creatorAsync.error!, creatorAsync.stackTrace!);
  }

  // 둘 다 성공
  if (manitoAsync.hasValue && creatorAsync.hasValue) {
    return AsyncValue.data((
      manito: manitoAsync.value!,
      creator: creatorAsync.value!,
    ));
  }

  return const AsyncValue.loading();
});

// ========== Notifier ==========
class MyProfileNotifier extends AsyncNotifier<MyProfile> {
  @override
  FutureOr<MyProfile> build() async {
    try {
      final service = ref.read(profileServiceProvider);
      final myProfile = await service.getMyProfile();
      return myProfile;
    } catch (e) {
      debugPrint('UserProfileNotifier.build Error: $e');
      rethrow;
    }
  }

  // 새로고침
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

class FriendProfileNotifier extends AsyncNotifier<FriendProfilesState> {
  @override
  FutureOr<FriendProfilesState> build() async {
    try {
      final service = ref.read(profileServiceProvider);
      final friendList = await service.fetchFriendList();
      final sortedList = List<FriendProfile>.from(friendList)
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
      return FriendProfilesState(friendList: sortedList);
    } catch (e) {
      debugPrint('FriendProfileNotifier.build Error: $e');
      return FriendProfilesState(friendList: []);
    }
  }

  // 새로고침
  Future<void> refreash() async {
    ref.invalidateSelf();
    await future;
  }

  // ========== 로컬 상태 변경 ==========
  void updateFriendNameInList(String id, String newName) {
    if (!state.hasValue) return;
    final currentState = state.value!;
    final currentList = currentState.friendList;
    final updateList =
        currentList.map((friend) {
          if (friend.id == id) {
            return friend.copyWith(nickname: newName);
          }
          return friend;
        }).toList();
    final updateData = currentState.copyWith(friendList: updateList);
    state = AsyncValue.data(updateData);
  }

  FriendProfile? findFriendById(String id) {
    final currentState = state.valueOrNull;
    if (currentState == null) return null;
    return currentState.friendList.firstWhereOrNull((f) => f.id == id);
  }

  // ID 로 친구 검색 - 한명
  FriendProfile searchFriendProfile(String friendId) {
    try {
      final myProfile = ref.read(myProfileProvider).value!;
      if (myProfile.id == friendId) {
        return FriendProfile(
          id: myProfile.id,
          nickname: myProfile.nickname,
          statusMessage: myProfile.statusMessage,
          profileImageUrl: myProfile.profileImageUrl,
        );
      }
      final friendProfile = state.value!.friendList.firstWhere(
        (friend) => friend.id == friendId,
        orElse: () => FriendProfile(id: 'unknown', nickname: 'unknown'),
      );
      return friendProfile;
    } catch (e) {
      debugPrint('FriendProfileNotifier.searchFriendProfile Error: $e');
      return FriendProfile(id: '', nickname: 'unknown');
    }
  }

  // ID 로 친구 검색 - 여러명
  List<FriendProfile> searchFriendProfiles(List<String> ids) {
    List<FriendProfile> friendProfiles = [];
    try {
      for (String id in ids) {
        final friendProfile = searchFriendProfile(id);
        friendProfiles.add(friendProfile);
      }
    } catch (e) {
      debugPrint('FriendProfileNotifier.searchFriendProfiles Error: $e');
    }
    return friendProfiles;
  }
}

class ProfileImageNotifier extends AutoDisposeNotifier<ProfileImageState> {
  @override
  ProfileImageState build() {
    try {
      final myProfile = ref.read(myProfileProvider).value;
      final profileImageUrl = myProfile!.profileImageUrl!;
      return ProfileImageState(
        selectedImage: null,
        profileImageUrl: profileImageUrl,
      );
    } catch (e) {
      debugPrint('ProfileImageNotifier.build Error: $e');
      return ProfileImageState();
    }
  }

  // 이미지 선택
  Future<void> pickImage() async {
    final service = ref.read(profileEditServiceProvider);
    final File? file = await service.pickImage();
    if (file != null) {
      state = state.copyWith(selectedImage: file);
    }
  }

  // 이미지 삭제
  void deleteImage() {
    state = state.copyWith(selectedImage: null, profileImageUrl: '');
  }
}

class ProfileEditNotifier extends AutoDisposeAsyncNotifier<ProfileEditState> {
  @override
  FutureOr<ProfileEditState> build() {
    try {
      final myProfile = ref.read(myProfileProvider).value!;
      return ProfileEditState(
        nickname: myProfile.nickname,
        statusMessage: myProfile.statusMessage!,
        autoReply: myProfile.autoReply!,
      );
    } catch (e) {
      debugPrint('ProfileEditNotifier.build Error: $e');
      return ProfileEditState();
    }
  }

  Future<void> updateProfile({
    required String nickname,
    required String statusMessage,
    required String autoReply,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final imageState = ref.read(profileImageProvider);
        final service = ref.read(profileEditServiceProvider);
        await service.updateProfile(
          nickname: nickname,
          statusMessage: statusMessage,
          autoReply: autoReply,
          selectedImage: imageState.selectedImage,
          profileImageUrl: imageState.profileImageUrl,
        );
        return ProfileEditState(
          nickname: nickname,
          statusMessage: statusMessage,
          autoReply: autoReply,
        );
      } catch (e) {
        debugPrint('ProfileEditNotifier.updateProfile Error: $e');
        rethrow;
      }
    });
  }
}

class GetProfileNotifier extends FamilyAsyncNotifier<UserProfile, String> {
  @override
  FutureOr<UserProfile> build(String id) async {
    final myProfile = ref.watch(myProfileProvider).value;
    if (myProfile!.id == id) {
      return UserProfile(
        id: id,
        nickname: myProfile.nickname,
        statusMessage: myProfile.statusMessage,
        profileImageUrl: myProfile.profileImageUrl,
      );
    }
    final friendList =
        ref.watch(friendProfilesProvider).value?.friendList ?? [];
    final cashedUser = friendList.firstWhereOrNull((u) => u.id == id);
    if (cashedUser != null) {
      return UserProfile(
        id: id,
        nickname: cashedUser.nickname,
        statusMessage: cashedUser.statusMessage,
        profileImageUrl: cashedUser.profileImageUrl,
        friendNickname: cashedUser.friendNickname,
      );
    }
    try {
      return ref.read(profileServiceProvider).getUserProfile(id);
    } catch (e) {
      debugPrint('GetProfileNotifier.build Error: $e');
      return UserProfile.unknown(id);
    }
  }
}
