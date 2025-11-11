import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features/error/error_provider.dart';
import 'package:manito/features/profiles/profile.dart';
import 'package:manito/features/profiles/profile_service.dart';

// ========== Service Provider ==========
final profileServiceProvider = Provider<ProfileService>((ref) {
  final supabase = ref.read(supabaseProvider);
  return ProfileService(supabase);
});

// ========== Notifier Provider ==========
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
      final service = ref.watch(profileServiceProvider);
      return UserProfileNotifier(service);
    });

// final userProfileProvider =
//     AsyncNotifierProvider<UserProfileNotifier2, UserProfile?>(
//   UserProfileNotifier2.new,
// );

// final friendProfilesProvider =
//     StateNotifierProvider<FriendProfilesNotifier, FriendProfilesState>((ref) {
//       final service = ref.watch(profileServiceProvider);
//       return FriendProfilesNotifier(ref, service);
//     });

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

final profileEditServiceProvider = Provider.autoDispose<ProfileEditService>((
  ref,
) {
  final supabase = ref.read(supabaseProvider);
  return ProfileEditService(supabase);
});

final profileEditProvider =
    StateNotifierProvider.autoDispose<ProfileEditNotifier, ProfileEditState>((
      ref,
    ) {
      final service = ref.watch(profileEditServiceProvider);
      return ProfileEditNotifier(service);
    });

// ========== Notifier ==========
class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final ProfileService _service;
  UserProfileNotifier(this._service) : super(const UserProfileState.initial());

  // 프로필 가져오기
  Future<void> getProfile() async {
    try {
      state = state.copyWith(isLoading: true);
      final userProfie = await _service.getProfile();
      state = state.copyWith(
        userProfile: userProfie,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      debugPrint('UserProfileNotifier.getProfile error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // 프로필 새로고침
  Future<void> refreshProfile() async {
    await getProfile();
  }
}

class UserProfileNotifier2 extends AsyncNotifier<UserProfile> {
  late final ProfileService _service;
  @override
  FutureOr<UserProfile> build() async {
    try {
      _service = ref.read(profileServiceProvider);
      return await _service.getProfile();
    } catch (e) {
      ref.read(errorProvider.notifier).setError('profile load error: $e');
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        return await _service.getProfile();
      } catch (e) {
        ref.read(errorProvider.notifier).setError('profile refresh error: $e');
        rethrow;
      }
    });
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
      ref
          .read(errorProvider.notifier)
          .setError('FriendProfileNotifier2 Error: $e');
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
      final userProfile = ref.read(userProfileProvider).userProfile;
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
      ref
          .read(errorProvider.notifier)
          .setError('searchFriendProfile Error: $e');
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
      ref
          .read(errorProvider.notifier)
          .setError('searchFriendProfiles Error: $e');
    }
    return friendProfiles;
  }
}

class ProfileEditNotifier extends StateNotifier<ProfileEditState> {
  final ProfileEditService _service;
  ProfileEditNotifier(this._service) : super(ProfileEditState.initial());

  // 프로필 수정하기
  Future<void> updateProfile({
    required String nickname,
    required String statusMessage,
    required String autoReply,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.updateProfile(
        nickname: nickname,
        statusMessage: statusMessage,
        autoReply: autoReply,
        selectedImage: state.selectedImage,
        profileImageUrl: state.profileImageUrl,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('ProfileImageNotifier.updateProfile error: $e');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // 이미지 선택하기
  Future<void> pickImage() async {
    final File? file = await _service.pickImage();
    if (file != null) {
      state = state.copyWith(selectedImage: file);
    }
  }

  void setInitialProfileImage(String profileImageUrl) {
    state = state.copyWith(
      selectedImage: null,
      profileImageUrl: profileImageUrl,
      isLoading: false,
    );
  }

  void selectedImage(File image) {
    state = state.copyWith(selectedImage: image, error: null);
  }

  void deleteImage() {
    state = state.copyWith(
      clearSelectedImage: true,
      profileImageUrl: '',
      error: null,
    );
  }

  void updateProfileImageUrl(String newUrl) {
    state = state.copyWith(
      profileImageUrl: newUrl,
      clearSelectedImage: true,
      error: null,
    );
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
