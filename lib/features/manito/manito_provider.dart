import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features/image/image_service.dart';
import 'package:manito/features/manito/manito.dart';
import 'package:manito/features/manito/manito_service.dart';
import 'package:manito/features/profiles/profile_provider.dart';
import 'package:photo_manager/photo_manager.dart';

// ========== Service Provider ==========
final manitoServiceProvider = Provider<ManitoService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ManitoService(supabase);
});

final manitoProposeServiceProvider = Provider<ManitoProposeService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ManitoProposeService(supabase);
});

final manitoPostServiceProvider = Provider<ManitoPostService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final imageService = ref.watch(imageServiceProvider);
  return ManitoPostService(supabase, imageService);
});

// ========== Notifier Provider ==========
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
  ManitoAccept
>(ManitoPostNotifier.new);

// ========== Notifier ==========
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

  /// 내부용: Accept 리스트 변환
  List<ManitoAccept> _convertAcceptList(List<dynamic> data) {
    final acceptList = <ManitoAccept>[];
    for (var acceptData in data) {
      final creatorId = acceptData['creator_id'];
      final creatorProfile = ref
          .read(friendProfilesProvider.notifier)
          .searchFriendProfile(creatorId);

      acceptList.add(ManitoAccept.fromJson(acceptData, creatorProfile));
    }
    return acceptList;
  }

  /// 내부용: Guess 리스트 변환
  List<ManitoGuess> _convertGuessList(List<dynamic> data) {
    final guessList = <ManitoGuess>[];
    for (var guessData in data) {
      final creatorId = guessData['creator_id'];
      final creatorProfile = ref
          .read(friendProfilesProvider.notifier)
          .searchFriendProfile(creatorId);

      guessList.add(ManitoGuess.fromJson(guessData, creatorProfile));
    }
    return guessList;
  }

  /// 내부용: 모든 목록 가져오기
  Future<ManitoListState> _fetchAll(String languageCode) async {
    final service = ref.read(manitoServiceProvider);
    final results = await Future.wait([
      service.fetchProposeList(),
      service.fetchAcceptList(languageCode),
      service.fetchGuessList(),
    ]);

    return ManitoListState(
      proposeList: results[0] as List<ManitoPropose>,
      acceptList: _convertAcceptList(results[1]),
      guessList: _convertGuessList(results[2]),
    );
  }

  /// 나에게 온 미션 제의
  Future<void> fetchProposeList() async {
    final currentState = state.valueOrNull ?? ManitoListState();

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(manitoServiceProvider);
      final proposeList = await service.fetchProposeList();

      return currentState.copyWith(proposeList: proposeList);
    });
  }

  /// 내가 수락한 미션 제의
  Future<void> fetchAcceptList(String languageCode) async {
    final currentState = state.valueOrNull ?? ManitoListState();

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(manitoServiceProvider);
      final acceptListData = await service.fetchAcceptList(languageCode);

      return currentState.copyWith(
        acceptList: _convertAcceptList(acceptListData),
      );
    });
  }

  /// 추측중 미션 목록 가져오기
  Future<void> fetchGuessList() async {
    final currentState = state.valueOrNull ?? ManitoListState();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(manitoServiceProvider);
      final guessListData = await service.fetchGuessList();

      return currentState.copyWith(guessList: _convertGuessList(guessListData));
    });
  }

  /// 모든 목록 새로고침
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

  /// 제안 정보 가져오기
  Future<ManitoProposeState> _getProposeDetail(String proposeId) async {
    state = const AsyncValue.loading();
    final nextState = await AsyncValue.guard(() async {
      final service = ref.read(manitoProposeServiceProvider);
      final languageCode = ref.read(languageCodeProvider);
      final proposeDetail = await service.getManitoPropose2(
        languageCode,
        proposeId,
      );

      return ManitoProposeState(propose: proposeDetail);
    });
    state = nextState;
    return nextState.requireValue;
  }

  /// 제안 수락하기
  Future<void> acceptPropose(String contentId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(isAccepting: true));
    try {
      final service = ref.read(manitoProposeServiceProvider);
      await service.acceptManitoPropose(
        currentState.propose!.missionId,
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
    extends FamilyAsyncNotifier<ManitoPostState, ManitoAccept> {
  @override
  FutureOr<ManitoPostState> build(ManitoAccept arg) async {
    try {
      final service = ref.read(manitoPostServiceProvider);
      final post = await service.getManitoPost(arg.id);
      return ManitoPostState(
        manitoAccept: arg,
        description: post.description ?? '',
        existingImageUrls: post.imageUrlList ?? [],
        status:
            post.description!.isEmpty
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

  // ========== 로컬 상태 변경 ==========
  // 이미지 추가
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

  // 새로 선택한 이미지 제거
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

  // 기존에 선택한 이미지 제거
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

  // 설명 업데이트
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

  // ========== 서버 통신 ==========
  // 게시물 저장
  Future<void> savePost() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // ✅ isSaving만 true로 (화면 전체 로딩 X)
    state = AsyncValue.data(
      currentState.copyWith(status: ManitoPostStatus.saving),
    );
    try {
      final service = ref.read(manitoPostServiceProvider);
      final uploadedImageUrls = await service.saveManitoPost(
        missionId: currentState.manitoAccept.id,
        description: currentState.description,
        existingImageUrls: currentState.existingImageUrls,
        selectedImages: currentState.selectedImages,
      );
      state = AsyncValue.data(
        currentState.copyWith(
          existingImageUrls: uploadedImageUrls,
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

  // 미션 완료
  Future<void> completePost() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    state = AsyncValue.data(
      currentState.copyWith(status: ManitoPostStatus.posting),
    );
    try {
      final service = ref.read(manitoPostServiceProvider);
      await service.completeManitoPost(
        missionId: currentState.manitoAccept.id,
        creatorId: currentState.manitoAccept.creatorProfile.id,
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
