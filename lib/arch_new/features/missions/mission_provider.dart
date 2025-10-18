import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/arch_new/core/providers.dart';
import 'package:manito/arch_new/features/missions/mission.dart';
import 'package:manito/arch_new/features/missions/mission_service.dart';
import 'package:manito/arch_new/features/profiles/profile.dart';
import 'package:manito/arch_new/features/profiles/profile_provider.dart';

// ========== Provider ==========
final missionServiceProvider = Provider<MissionService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return MissionService(supabase);
});

final missionCreateServiceProvider = Provider<MissionCreateService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return MissionCreateService(supabase);
});

final missionGuessServiceProvider = Provider<MissionGuessService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return MissionGuessService(supabase);
});

final missionListProvider =
    StateNotifierProvider<MissionListNotifier, MyMissionState>((ref) {
      final service = ref.watch(missionServiceProvider);
      return MissionListNotifier(ref, service);
    });

final missionCreateProvider = StateNotifierProvider.autoDispose<
  MissionCreateNotifier,
  MissionCreateState
>((ref) {
  final service = ref.watch(missionCreateServiceProvider);
  return MissionCreateNotifier(ref, service);
});

final missionGuessProvider =
    StateNotifierProvider.autoDispose<MissionGuessNotifier, MissionGuessState>((
      ref,
    ) {
      final service = ref.watch(missionGuessServiceProvider);
      return MissionGuessNotifier(service);
    });

// ========== Notifier ==========
class MissionListNotifier extends StateNotifier<MyMissionState> {
  final Ref _ref;
  final MissionService _service;
  MissionListNotifier(this._ref, this._service) : super(MyMissionState());

  String get _currentUserId => _ref.read(currentUserProvider)!.id;

  /// 내가 생성한 미션 리스트 가져오기 - 대기, 진행중, 완료
  Future<void> fetchMyMissions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Friends Provider에서 친구 목록 가져오기
      final friendsState = _ref.read(friendProfilesProvider);
      if (!friendsState.isLoading && friendsState.friendList.isEmpty) {
        await _ref.read(friendProfilesProvider.notifier).fetchFriendList();
      }
      int attempts = 0;
      while (_ref.read(friendProfilesProvider).isLoading && attempts < 20) {
        await Future.delayed(const Duration(microseconds: 500));
        attempts++;
      }

      final updatedFriendState = _ref.read(friendProfilesProvider);
      if (updatedFriendState.friendList.isEmpty) {
        state = state.copyWith(
          allMissions: [],
          pendingMyMissions: [],
          acceptMyMissions: [],
          completeMyMissions: [],
          isLoading: false,
          error: null,
        );
        debugPrint('친구가 없어서 미션을 가져올 수 없습니다.');
        return;
      }

      // 미션 데이터 가져오기
      final missionsData = await _service.fetchMyMissionsData(_currentUserId);

      // 각 미션에 친구 프로필 추가
      final List<MyMission> allMissions = [];
      for (var missionData in missionsData) {
        final List<String> friendIds = List<String>.from(
          missionData['friend_ids'] ?? [],
        );

        // 친구 프로필 검색
        final List<FriendProfile> friendProfiles = _ref
            .read(friendProfilesProvider.notifier)
            .searchFriendProfiles(friendIds);

        final myMission = MyMission.fromJson(missionData, friendProfiles);
        allMissions.add(myMission);
      }

      // 상태별로 미션 분류
      final pendingMissions =
          allMissions.where((mission) => mission.status == 'pending').toList();

      final acceptMissions =
          allMissions
              .where((mission) => mission.status == 'progressing')
              .toList();

      final completeMissions =
          allMissions.where((mission) => mission.status == 'guessing').toList();

      state = state.copyWith(
        allMissions: allMissions,
        pendingMyMissions: pendingMissions,
        acceptMyMissions: acceptMissions,
        completeMyMissions: completeMissions,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('MissionNotifier.fetchMyMissions Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class MissionCreateNotifier extends StateNotifier<MissionCreateState> {
  final Ref _ref;
  final MissionCreateService _service;

  MissionCreateNotifier(this._ref, this._service) : super(MissionCreateState());
  String get _currentUserId => _ref.read(currentUserProvider)!.id;

  /// 체크 상태 토글 함수
  void toggleSelection(FriendProfile friendProfile) {
    final currentSelected = List<FriendProfile>.from(state.selectedFriends);

    if (currentSelected.contains(friendProfile)) {
      currentSelected.remove(friendProfile);
    } else {
      currentSelected.add(friendProfile);
    }

    state = state.copyWith(selectedFriends: currentSelected);
  }

  /// 체크 상태 확인 함수
  bool isSelected(FriendProfile friendProfile) {
    return state.selectedFriends.contains(friendProfile);
  }

  /// 선택했던 친구 동기화
  void updateSelectedFriends() {
    state = state.copyWith(selectedFriends: List.from(state.confirmedFriends));
  }

  /// 선택한 친구 확정하기
  void confirmSelection() {
    state = state.copyWith(confirmedFriends: List.from(state.selectedFriends));
  }

  /// 선택 초기화
  void clearSelection() {
    state = state.copyWith(selectedFriends: [], confirmedFriends: []);
  }

  // 미션 생성
  Future<String> createMission(int selectedType, int selectedPeriod) async {
    state = state.copyWith(isLoading: true, error: null);
    final List<String> friendIds =
        state.confirmedFriends.map((friend) => friend.id).toList();

    String contentType;
    switch (selectedType) {
      case 0:
        contentType = 'daily';
        break;
      case 1:
        contentType = 'school';
        break;
      case 2:
        contentType = 'work';
        break;
      default:
        contentType = 'work';
        break;
    }
    String deadlineType = selectedPeriod == 0 ? 'day' : 'week';

    try {
      final result = await _service.createMission(
        creatorId: _currentUserId,
        friendIds: friendIds,
        contentType: contentType,
        deadlineType: deadlineType,
      );

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      debugPrint('MissionCreateNotifier.createMission: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return e.toString();
    }
  }
}

class MissionGuessNotifier extends StateNotifier<MissionGuessState> {
  final MissionGuessService _service;
  MissionGuessNotifier(this._service) : super(MissionGuessState());

  Future<void> updateMissionGuess(String missionId, String text) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.updateMissionGuess(missionId, text);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      debugPrint('MissionGuessNotifier.updateMissionGuess: $e');
    }
  }
}
