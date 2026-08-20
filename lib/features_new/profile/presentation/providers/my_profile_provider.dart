import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';
import 'package:manito/features_new/profile/domain/repositories/repository_provider.dart';

class MyProfileNotifier extends AsyncNotifier<MyProfileEntity?> {
  @override
  FutureOr<MyProfileEntity?> build() {
    final repository = ref.watch(profileRepositoryProvider);
    return repository.getMyProfile();
  }

  // 새로고침
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  // 프로필 수정
  Future<void> updateProfile({
    required String nickname,
    required String statusMessage,
    required String autoReply,
    File? imageFile,
    String? existingImageUrl,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(profileRepositoryProvider);
      final updateProfile = await repository.updateMyProfile(
        nickname: nickname,
        statusMessage: statusMessage,
        autoReply: autoReply,
        imageFile: imageFile,
        existingImageUrl: existingImageUrl,
      );
      return updateProfile;
    });
  }
}

final myProfileProvider =
    AsyncNotifierProvider<MyProfileNotifier, MyProfileEntity?>(() {
      return MyProfileNotifier();
    });

final userProfileProvider = FutureProvider.family<UserEntity, String>((ref, userId) {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getUserProfile(userId);
});

final combinedProfileProvider = Provider.family<
  AsyncValue<({UserEntity manito, UserEntity creator})>,
  ({String manitoId, String creatorId})
>((ref, ids) {
  final manitoAsync = ref.watch(userProfileProvider(ids.manitoId));
  final creatorAsync = ref.watch(userProfileProvider(ids.creatorId));

  if (manitoAsync.isLoading || creatorAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (manitoAsync.hasError) {
    return AsyncValue.error(
      manitoAsync.error!,
      manitoAsync.stackTrace ?? StackTrace.current,
    );
  }

  if (creatorAsync.hasError) {
    return AsyncValue.error(
      creatorAsync.error!,
      creatorAsync.stackTrace ?? StackTrace.current,
    );
  }

  return AsyncValue.data((
    manito: manitoAsync.value!,
    creator: creatorAsync.value!,
  ));
});
