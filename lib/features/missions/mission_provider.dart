import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features/error/error_provider.dart';
import 'package:manito/features/missions/mission.dart';
import 'package:manito/features/missions/mission_service.dart';
import 'package:manito/features/profiles/profile.dart';
import 'package:manito/features/profiles/profile_provider.dart';

// ========== Service Provider ==========
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

// ========== Notifier Provider ==========

final missionListProvider =
    AsyncNotifierProvider<MissionListNotifier, MyMissionState>(
      MissionListNotifier.new,
    );

final missionCreateProvider = StateNotifierProvider.autoDispose<
  MissionCreateNotifier,
  MissionCreateState
>((ref) {
  final service = ref.watch(missionCreateServiceProvider);
  return MissionCreateNotifier(service);
});

final missionGuessProvider = AsyncNotifierProvider<MissionGuessNotifier, void>(
  MissionGuessNotifier.new,
);

// ========== Notifier ==========
class MissionListNotifier extends AsyncNotifier<MyMissionState> {
  @override
  FutureOr<MyMissionState> build() async {
    try {
      final friendsState = ref.watch(friendProfilesProvider);
      final friendList = friendsState.value?.friendList;
      if (friendList == null || friendList.isEmpty) return MyMissionState();
      return await _fetchMyMissions(friendList);
    } catch (e) {
      ref.read(errorProvider.notifier).setError('fetchMyMissions Error: $e');
      return MyMissionState();
    }
  }

  // 미션 목록 가져오기
  Future<MyMissionState> _fetchMyMissions(List<FriendProfile> friends) async {
    final service = ref.read(missionServiceProvider);
    final missionsData = await service.fetchMyMissionsData();
    final allMissions = <MyMission>[];
    for (var missionData in missionsData) {
      final friendIds = List<String>.from(missionData['friend_ids'] ?? []);
      final friendProfiles =
          friends.where((f) => friendIds.contains(f.id)).toList();
      allMissions.add(MyMission.fromJson(missionData, friendProfiles));
    }

    return MyMissionState(
      allMissions: allMissions,
      pendingMyMissions:
          allMissions.where((m) => m.status == 'pending').toList(),
      acceptMyMissions:
          allMissions.where((m) => m.status == 'progressing').toList(),
      completeMyMissions:
          allMissions.where((m) => m.status == 'guessing').toList(),
    );
  }

  // 새로고침
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

class MissionCreateNotifier extends StateNotifier<MissionCreateState> {
  final MissionCreateService _service;

  MissionCreateNotifier(this._service) : super(MissionCreateState());

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
  Future<void> createMission(int selectedType, int selectedPeriod) async {
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
      await _service.createMission(
        friendIds: friendIds,
        contentType: contentType,
        deadlineType: deadlineType,
      );

      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('MissionCreateNotifier.createMission: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class MissionCreateNotifier2 extends AsyncNotifier<MissionCreateState> {
  @override
  FutureOr<MissionCreateState> build() {
    return MissionCreateState();
  }

  // // 미션 생성
  // Future<void> createMission(int selectedType, int selectedPeriod) async {
  //   state = const AsyncLoading();
  //   try {
  //     final confirmedFriends = state.value!.confirmedFriends;
  //     final friendIds = confirmedFriends.map((friend) => friend.id).toList();
  //     final contentType = switch (selectedType) {
  //       0 => 'daily',
  //       1 => 'school',
  //       2 => 'work',
  //       _ => 'daily',
  //     };
  //     String deadlineType = selectedPeriod == 0 ? 'day' : 'week';
  //     final service = ref.read(missionCreateServiceProvider);
  //     state = await AsyncValue.guard(() async {
  //       await service.createMission(
  //         friendIds: friendIds,
  //         contentType: contentType,
  //         deadlineType: deadlineType,
  //       );
  //       return MissionCreateState();
  //     });
  //   } catch (e) {
  //     ref.read(errorProvider.notifier).setError('createMission Error: $e');
  //   }
  // }
}

class MissionGuessNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  // 추측 업데이트
  Future<void> updateMissionGuess(String missionId, String text) async {
    state = const AsyncValue.loading();
    try {
      state = await AsyncValue.guard(() async {
        final service = ref.read(missionGuessServiceProvider);
        await service.updateMissionGuess(missionId, text);
      });
    } catch (e) {
      ref.read(errorProvider.notifier).setError('updateMissionGuess Error: $e');
      rethrow;
    }
  }
}
