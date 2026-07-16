import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/features_new/friends/presentation/providers/friend_list_provider.dart';
import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';
import 'package:manito/features_new/profile/presentation/providers/my_profile_provider.dart';
import 'package:manito/features_new/profile/domain/repositories/repository_provider.dart';

final userProfileProvider = FutureProvider.family<UserEntity, String>((
  ref,
  userId,
) async {
  // 1. 내 프로필 확인
  final myProfileState = ref.watch(myProfileProvider);
  final myProfile = myProfileState.value;
  if (myProfile != null && myProfile.id == userId) {
    return myProfile;
  }

  // 2. 친구 목록 프로필 확인
  final friendListState = ref.watch(friendListProvider);
  final friendList = friendListState.value ?? [];
  final matchedFriend = friendList.where((f) => f.id == userId).toList();
  if (matchedFriend.isNotEmpty) {
    return matchedFriend.first;
  }

  // 3. 서버에서 프로필 확인
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getUserProfile(userId);
});
