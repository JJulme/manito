import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfileState>(
      UserProfileNotifier.new,
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
    NotifierProvider<ProfileImageNotifier, ProfileImageState>(
      ProfileImageNotifier.new,
    );

final profileEditProvider =
    AsyncNotifierProvider<ProfileEditNotifier, ProfileEditState>(
      ProfileEditNotifier.new,
    );

// ========== Notifier ==========
class UserProfileNotifier extends AsyncNotifier<UserProfileState> {
  @override
  FutureOr<UserProfileState> build() async {
    try {
      final service = ref.read(profileServiceProvider);
      final userProfile = await service.getProfile();
      return UserProfileState(userProfile: userProfile);
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

  // ID 로 친구 검색 - 한명
  FriendProfile searchFriendProfile(String friendId) {
    try {
      final userProfile = ref.read(userProfileProvider).value!.userProfile;
      if (userProfile != null && userProfile.id == friendId) {
        return FriendProfile(
          id: userProfile.id,
          nickname: userProfile.nickname,
          statusMessage: userProfile.statusMessage,
          profileImageUrl: userProfile.profileImageUrl,
        );
      }
      final friendProfile = state.value!.friendList.firstWhere(
        (friend) => friend.id == friendId,
        orElse: () => FriendProfile(id: '', nickname: 'unknown'),
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

class ProfileImageNotifier extends Notifier<ProfileImageState> {
  @override
  ProfileImageState build() {
    try {
      final userProfile = ref.read(userProfileProvider).value!.userProfile;
      final profileImageUrl = userProfile!.profileImageUrl!;
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

class ProfileEditNotifier extends AsyncNotifier<ProfileEditState> {
  @override
  FutureOr<ProfileEditState> build() {
    try {
      final userProfile = ref.read(userProfileProvider).value!.userProfile!;
      return ProfileEditState(
        nickname: userProfile.nickname,
        statusMessage: userProfile.statusMessage!,
        autoReply: userProfile.autoReply!,
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
