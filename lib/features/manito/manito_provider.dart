import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features/image/image_service.dart';
import 'package:manito/features/manito/manito.dart';
import 'package:manito/features/manito/manito_service.dart';
import 'package:manito/features/profiles/profile.dart';
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
    StateNotifierProvider<ManitoListNotifier, ManitoListState>((ref) {
      final service = ref.watch(manitoServiceProvider);
      return ManitoListNotifier(ref, service);
    });

StateNotifierProvider<ManitoProposeNotifier, ManitoProposeState>
createManitoProposeProvider(ManitoPropose originalPropose) {
  return StateNotifierProvider<ManitoProposeNotifier, ManitoProposeState>((
    ref,
  ) {
    final service = ref.watch(manitoProposeServiceProvider);
    return ManitoProposeNotifier(service, originalPropose);
  });
}

// final manitoProposeProvider = StateNotifierProvider.family
//     .autoDispose<ManitoProposeNotifier, ManitoProposeState, ManitoPropose>((ref, originalPropose) {
//   final service = ref.watch(manitoProposeServiceProvider);
//   final notifier = ManitoProposeNotifier(service, originalPropose);

//   // 화면 진입 후 자동 데이터 fetch
//   Future.microtask(() => notifier.getPropose(ref.read(localeProvider))); // 필요 시 localeProvider 사용

//   return notifier;
// });

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
class ManitoListNotifier extends StateNotifier<ManitoListState> {
  final Ref _ref;
  final ManitoService _service;
  ManitoListNotifier(this._ref, this._service) : super(ManitoListState());

  // 나에게 온 미션 제의 목록 가져오기
  Future<void> fetchProposeList() async {
    try {
      final proposeList = await _service.fetchProposeList();
      state = state.copyWith(proposeList: proposeList);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 내가 수락한 미션 목록 가져오기
  Future<void> fetchAcceptList(String languageCode) async {
    try {
      final acceptList = await _service.fetchAcceptList(languageCode);
      final List<ManitoAccept> allAcceptList = [];
      for (var acceptData in acceptList) {
        final creatorId = acceptData['creator_id'];
        final FriendProfile? creatorProfile = _ref
            .read(friendProfilesProvider.notifier)
            .searchFriendProfile(creatorId);
        final manitoAccept = ManitoAccept.fromJson(acceptData, creatorProfile!);
        allAcceptList.add(manitoAccept);
      }
      state = state.copyWith(acceptList: allAcceptList);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 추측중 미션 목록 가져오기
  Future<void> fetchGuessList() async {
    try {
      final guessList = await _service.fetchGuessList();
      final List<ManitoGuess> allGuessList = [];
      for (var guessData in guessList) {
        final creatorId = guessData['creator_id'];
        final FriendProfile? creatorProfile = _ref
            .read(friendProfilesProvider.notifier)
            .searchFriendProfile(creatorId);
        final manitoGuess = ManitoGuess.fromJson(guessData, creatorProfile!);
        allGuessList.add(manitoGuess);
      }
      state = state.copyWith(guessList: allGuessList);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 모든 목록 새로고침
  Future<void> refreshAll(String languageCode) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.wait([
        fetchProposeList(),
        fetchAcceptList(languageCode),
        fetchGuessList(),
      ]);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

class ManitoProposeNotifier extends StateNotifier<ManitoProposeState> {
  final ManitoProposeService _service;
  final ManitoPropose originalPropose;
  ManitoProposeNotifier(this._service, this.originalPropose)
    : super(ManitoProposeState.initial(originalPropose));

  // 제안 정보 가져오기
  Future<void> getPropose(String languageCode) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      if (state.propose!.isDetailLoaded) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final ManitoPropose data = await _service.getManitoPropose(
        languageCode,
        originalPropose,
      );
      state = state.copyWith(isLoading: false, propose: data);
    } catch (e) {
      debugPrint('ManitoProposeNotifier.getPropose Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // 제안 수락하기
  Future<void> acceptPropose(String contentId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.acceptManitoPropose(state.propose!.missionId!, contentId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('ManitoProposeNotifier.acceptPropose Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
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
