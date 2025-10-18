import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/arch_new/core/providers.dart';
import 'package:manito/arch_new/features/profiles/profile.dart';
import 'package:manito/arch_new/features/profiles/profile_service.dart';

// ========== Provider ==========
final profileServiceProvider = Provider<ProfileService>((ref) {
  final supabase = ref.read(supabaseProvider);
  return ProfileService(supabase);
});

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
      final service = ref.watch(profileServiceProvider);
      return UserProfileNotifier(service);
    });

final friendProfilesProvider =
    StateNotifierProvider<FriendProfilesNotifier, FriendProfilesState>((ref) {
      final service = ref.watch(profileServiceProvider);
      return FriendProfilesNotifier(ref, service);
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

class FriendProfilesNotifier extends StateNotifier<FriendProfilesState> {
  final Ref _ref;
  final ProfileService _service;
  FriendProfilesNotifier(this._ref, this._service)
    : super(const FriendProfilesState.initial());

  Future<void> fetchFriendList() async {
    try {
      state = state.copyWith(isLoading: true);
      final friendList = await _service.fetchFriendList();

      state = state.copyWith(
        friendList: friendList,
        isLoading: false,
        error: null,
      );
      // 이름 순서 정렬
      state.friendList.sort((a, b) => a.displayName.compareTo(b.displayName));
    } catch (e) {
      debugPrint('FriendProfilesNotifier.fetchFriendList error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshFriendList() async {
    await fetchFriendList();
  }

  // ID 로 친구 검색 - 한명
  FriendProfile? searchFriendProfile(String friendId) {
    try {
      final userProfile = _ref.read(userProfileProvider).userProfile;
      // 사용자의 id가 들어오면 사용자의 id를 반환
      if (userProfile != null && userProfile.id == friendId) {
        return FriendProfile(
          id: userProfile.id,
          nickname: userProfile.nickname,
          statusMessage: userProfile.statusMessage,
          profileImageUrl: userProfile.profileImageUrl,
        );
      }
      final friendProfile = state.friendList.firstWhere(
        (friend) => friend.id == friendId,
        orElse:
            () =>
                FriendProfile(id: '', nickname: 'unknown', profileImageUrl: ''),
      );

      return friendProfile;
    } catch (e) {
      debugPrint('FriendProfilesNotifier.searchFriendProfile error: $e');
      return null;
    }
  }

  // ID 로 친구 검색 - 여러명
  List<FriendProfile> searchFriendProfiles(List<String> ids) {
    List<FriendProfile> friendProfiles = [];
    try {
      for (String id in ids) {
        final friendProfile = searchFriendProfile(id);
        if (friendProfile != null) {
          friendProfiles.add(friendProfile);
        }
      }
    } catch (e) {
      debugPrint('FriendProfilesNotifier.searchFriendProfiles error: $e');
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
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.updateProfile(
        nickname: nickname,
        statusMessage: statusMessage,
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
