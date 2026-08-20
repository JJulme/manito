import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features_new/friends/domain/entities/friend_entity.dart';
import 'package:manito/features_new/friends/presentation/providers/friend_list_provider.dart';
import 'package:manito/features_new/manito/domain/entities/manito_entity.dart';
import 'package:manito/features_new/manito/domain/repositories/repository_provider.dart';
import 'package:photo_manager/photo_manager.dart';

// ========== Notifier Providers ==========
final manitoListProvider =
    AsyncNotifierProvider<ManitoListNotifier, ManitoListState>(
  ManitoListNotifier.new,
);

final manitoProposeProvider = AsyncNotifierProvider.family<
  ManitoProposeNotifier,
  ManitoProposeState,
  String
>(ManitoProposeNotifier.new);

final manitoPostProvider = AsyncNotifierProvider.family<
  ManitoPostNotifier,
  ManitoPostState,
  ManitoAcceptEntity
>(ManitoPostNotifier.new);

// ========== Notifiers ==========
class ManitoListNotifier extends AsyncNotifier<ManitoListState> {
  @override
  Future<ManitoListState> build() async {
    try {
      final languageCode = ref.read(languageCodeProvider);
      return _fetchAll(languageCode);
    } catch (e) {
      debugPrint('ManitoListNotifier.build Error: $e');
      return ManitoListState();
    }
  }

  List<ManitoAcceptEntity> _convertAcceptList(List<dynamic> data) {
    final friendList = ref.read(friendListProvider).value ?? [];
    final acceptList = <ManitoAcceptEntity>[];
    for (var acceptData in data) {
      final creatorId = acceptData['creator_id'];
      final creatorProfile = friendList.firstWhere(
        (f) => f.id == creatorId,
        orElse: () => FriendProfileEntity(id: creatorId, nickname: '알 수 없음'),
      );
      acceptList.add(ManitoAcceptEntity.fromJson(acceptData, creatorProfile));
    }
    return acceptList;
  }

  List<ManitoGuessEntity> _convertGuessList(List<dynamic> data) {
    final friendList = ref.read(friendListProvider).value ?? [];
    final guessList = <ManitoGuessEntity>[];
    for (var guessData in data) {
      final creatorId = guessData['creator_id'];
      final creatorProfile = friendList.firstWhere(
        (f) => f.id == creatorId,
        orElse: () => FriendProfileEntity(id: creatorId, nickname: '알 수 없음'),
      );
      guessList.add(ManitoGuessEntity.fromJson(guessData, creatorProfile));
    }
    return guessList;
  }

  Future<ManitoListState> _fetchAll(String languageCode) async {
    final repository = ref.read(manitoRepositoryProvider);
    final results = await Future.wait([
      repository.fetchProposeList(),
      repository.fetchAcceptData(languageCode),
      repository.fetchGuessData(),
    ]);

    return ManitoListState(
      proposeList: results[0] as List<ManitoProposeEntity>,
      acceptList: _convertAcceptList(results[1] as List<Map<String, dynamic>>),
      guessList: _convertGuessList(results[2] as List<Map<String, dynamic>>),
    );
  }

  Future<void> fetchProposeList() async {
    final currentState = state.valueOrNull ?? ManitoListState();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(manitoRepositoryProvider);
      final proposeList = await repository.fetchProposeList();
      return currentState.copyWith(proposeList: proposeList);
    });
  }

  Future<void> fetchAcceptList(String languageCode) async {
    final currentState = state.valueOrNull ?? ManitoListState();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(manitoRepositoryProvider);
      final acceptListData = await repository.fetchAcceptData(languageCode);
      return currentState.copyWith(
        acceptList: _convertAcceptList(acceptListData),
      );
    });
  }

  Future<void> fetchGuessList() async {
    final currentState = state.valueOrNull ?? ManitoListState();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(manitoRepositoryProvider);
      final guessListData = await repository.fetchGuessData();
      return currentState.copyWith(guessList: _convertGuessList(guessListData));
    });
  }

  Future<void> refreshAll(String languageCode) async {
    ref.invalidateSelf();
    await future;
  }
}

class ManitoProposeNotifier
    extends FamilyAsyncNotifier<ManitoProposeState, String> {
  @override
  FutureOr<ManitoProposeState> build(String proposeId) async {
    return await _getProposeDetail(proposeId);
  }

  Future<ManitoProposeState> _getProposeDetail(String proposeId) async {
    state = const AsyncValue.loading();
    final nextState = await AsyncValue.guard(() async {
      final repository = ref.read(manitoRepositoryProvider);
      final languageCode = ref.read(languageCodeProvider);
      final proposeDetail = await repository.fetchProposeDetail(
        proposeId,
        languageCode,
      );
      return ManitoProposeState(propose: proposeDetail);
    });
    state = nextState;
    return nextState.requireValue;
  }

  Future<void> acceptPropose(String contentId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(isAccepting: true));
    try {
      final repository = ref.read(manitoRepositoryProvider);
      await repository.acceptPropose(
        currentState.propose!.missionId!,
        contentId,
      );
      state = AsyncValue.data(currentState.copyWith(isAccepting: false));
    } catch (e) {
      debugPrint('ManitoProposeNotifier.acceptPropose Error: $e');
      state = AsyncValue.data(currentState.copyWith(isAccepting: false));
    }
  }
}

class ManitoPostNotifier
    extends FamilyAsyncNotifier<ManitoPostState, ManitoAcceptEntity> {
  @override
  FutureOr<ManitoPostState> build(ManitoAcceptEntity arg) async {
    try {
      final repository = ref.read(manitoRepositoryProvider);
      final post = await repository.getManitoPost(arg.id);
      return ManitoPostState(
        manitoAccept: arg,
        description: post?.description ?? '',
        existingImageUrls: post?.imageUrlList ?? [],
        status: (post?.description?.isEmpty ?? true)
            ? ManitoPostStatus.editing
            : ManitoPostStatus.saved,
      );
    } catch (e) {
      debugPrint('ManitoPostNotifier.build Error: $e');
      return ManitoPostState(
        manitoAccept: arg,
        status: ManitoPostStatus.editing,
      );
    }
  }

  void addImages(List<AssetEntity> selectedAssets) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    state = AsyncValue.data(
      currentState.copyWith(
        selectedImages: selectedAssets,
        status: ManitoPostStatus.editing,
      ),
    );
  }

  void removeSelectedImage(int index) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    final newSelectedImages = List<AssetEntity>.from(
      currentState.selectedImages,
    );
    newSelectedImages.removeAt(index);
    state = AsyncValue.data(
      currentState.copyWith(
        selectedImages: newSelectedImages,
        status: ManitoPostStatus.editing,
      ),
    );
  }

  void removeExistingImage(int index) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    final newExistingImages = List<String>.from(currentState.existingImageUrls);
    newExistingImages.removeAt(index);
    state = AsyncValue.data(
      currentState.copyWith(
        existingImageUrls: newExistingImages,
        status: ManitoPostStatus.editing,
      ),
    );
  }

  void updateDescription(String description) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    state = AsyncValue.data(
      currentState.copyWith(
        description: description,
        status: ManitoPostStatus.editing,
      ),
    );
  }

  Future<void> savePost() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncValue.data(
      currentState.copyWith(status: ManitoPostStatus.saving),
    );
    try {
      final repository = ref.read(manitoRepositoryProvider);
      final uploadedUrls = await repository.uploadImages(currentState.selectedImages);
      final finalUrls = [...currentState.existingImageUrls, ...uploadedUrls];

      await repository.saveManitoPost(
        currentState.manitoAccept.id,
        currentState.description,
        currentState.selectedImages,
      );
      state = AsyncValue.data(
        currentState.copyWith(
          existingImageUrls: finalUrls,
          selectedImages: [],
          status: ManitoPostStatus.saved,
        ),
      );
    } catch (e) {
      debugPrint('ManitoPostNotifier.savePost Error: $e');
      state = AsyncValue.data(
        currentState.copyWith(status: ManitoPostStatus.editing),
      );
    }
  }

  Future<void> completePost() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    state = AsyncValue.data(
      currentState.copyWith(status: ManitoPostStatus.posting),
    );
    try {
      final repository = ref.read(manitoRepositoryProvider);
      await repository.completeManitoPost(
        currentState.manitoAccept.id,
        currentState.description,
        currentState.selectedImages,
      );
      state = AsyncValue.data(
        currentState.copyWith(status: ManitoPostStatus.posted),
      );
    } catch (e) {
      debugPrint('ManitoPostNotifier.completePost Error: $e');
      state = AsyncValue.data(
        currentState.copyWith(status: ManitoPostStatus.saved),
      );
    }
  }
}
