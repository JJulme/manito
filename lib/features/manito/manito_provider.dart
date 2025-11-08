import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features/error/error_provider.dart';
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

final manitoPostProvider = StateNotifierProvider.family
    .autoDispose<ManitoPostNotifier, ManitoPostState, ManitoAccept>((
      ref,
      manitoAccept,
    ) {
      final service = ref.watch(manitoPostServiceProvider);
      final notifier = ManitoPostNotifier(
        service: service,
        manitoAccept: manitoAccept,
      );
      Future.microtask(() => notifier.getPost());
      return notifier;
    });

// ========== Notifier ==========
class ManitoListNotifier extends AsyncNotifier<ManitoListState> {
  @override
  Future<ManitoListState> build() async {
    try {
      final languageCode = ref.read(languageCodeProvider);
      return _fetchAll(languageCode);
    } catch (e) {
      ref.read(errorProvider.notifier).setError('마니또 목록 가져오기 실패: $e');
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

      if (creatorProfile != null) {
        acceptList.add(ManitoAccept.fromJson(acceptData, creatorProfile));
      }
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

      if (creatorProfile != null) {
        guessList.add(ManitoGuess.fromJson(guessData, creatorProfile));
      }
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
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAll(languageCode));
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
      try {
        final service = ref.read(manitoProposeServiceProvider);
        final languageCode = ref.read(languageCodeProvider);
        final proposeDetail = await service.getManitoPropose2(
          languageCode,
          proposeId,
        );

        return ManitoProposeState(propose: proposeDetail);
      } catch (e) {
        ref.read(errorProvider.notifier).setError('마니또 제안 가져오기 실패: $e');
        return ManitoProposeState();
      }
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
      ref.read(errorProvider.notifier).setError('제안 수락 실패: $e');
      state = AsyncValue.data(currentState.copyWith(isAccepting: false));
    }
  }
}

class ManitoPostNotifier extends StateNotifier<ManitoPostState> {
  final ManitoPostService _service;
  ManitoPostNotifier({
    required ManitoPostService service,
    required ManitoAccept manitoAccept,
  }) : _service = service,
       super(ManitoPostState(manitoAccept: manitoAccept));

  // 입력했던 정보 가져오기
  Future<void> getPost() async {
    try {
      state = state.setLoading();
      final post = await _service.getManitoPost(state.manitoAccept.id);
      state = state.setLoaded(post);
    } catch (e) {
      state = state.setError('게시물을 불러올 수 없습니다.');
      debugPrint('ManitoPostNotifier.getPost Error: $e');
    }
  }

  // 앨범에서 선택한 이미지 저장
  void addImages(List<AssetEntity> selectedAssets) {
    state = state.addSelectedImage(selectedAssets);
  }

  /// 선택한 이미지 삭제
  void removeSelectedImage(int index) {
    state = state.removeSelectedImage(index);
  }

  /// 기존 이미지 삭제
  void removeExistingImage(int index) {
    state = state.removeExistingImage(index);
  }

  /// 설명 업데이트
  void updateDescription(String description) {
    // if (!state.canEdit) return;
    state = state.updateDescription(description);
  }

  // 게시물 저장
  Future<void> savePost() async {
    state = state.setSaving();
    try {
      final uploadedImageUrls = await _service.saveManitoPost(
        missionId: state.manitoAccept.id,
        description: state.description,
        existingImageUrls: state.existingImageUrls,
        selectedImages: state.selectedImages,
      );
      state = state.setSaved(uploadedImageUrls);
    } catch (e) {
      state = state.setError(e.toString());
      debugPrint('ManitoPostNotifier.savePost: $e');
    }
  }

  // 미션 완료
  Future<void> completePost() async {
    state = state.setPosting();
    try {
      await _service.completeManitoPost(
        missionId: state.manitoAccept.id,
        creatorId: state.manitoAccept.creatorProfile.id,
      );
      state = state.setPosted();
    } catch (e) {
      state = state.setError(e.toString());
      debugPrint('ManitoPostNotifier.completePost: $e');
    }
  }
}
