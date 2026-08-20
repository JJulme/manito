import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/utils/calculator_service.dart';
import 'package:manito/features_new/friends/domain/entities/friend_entity.dart';
import 'package:manito/features_new/friends/presentation/providers/friend_list_provider.dart';
import 'package:manito/features_new/missions/domain/entities/mission_entity.dart';
import 'package:manito/features_new/missions/domain/repositories/repository_provider.dart';

// ========== Providers ==========
final missionListProvider =
    AsyncNotifierProvider<MissionListNotifier, MyMissionState>(() {
  return MissionListNotifier();
});

final missionCreateSelectionProvider =
    NotifierProvider.autoDispose<MissionCreateSelectionNotifier, MissionCreateSelectionEntity>(
  MissionCreateSelectionNotifier.new,
);

final missionCreationActionProvider =
    AsyncNotifierProvider.autoDispose<MissionCreationActionNotifier, void>(
  MissionCreationActionNotifier.new,
);

final missionGroupRoomCreationActionProvider =
    AsyncNotifierProvider.autoDispose<MissionGroupRoomCreationActionNotifier, String>(
  MissionGroupRoomCreationActionNotifier.new,
);

final missionGuessProvider =
    AsyncNotifierProvider.autoDispose<MissionGuessNotifier, void>(
  MissionGuessNotifier.new,
);

// ========== Notifiers ==========
class MissionListNotifier extends AsyncNotifier<MyMissionState> {
  @override
  FutureOr<MyMissionState> build() async {
    try {
      final friendListAsync = ref.watch(friendListProvider);
      final friendList = friendListAsync.value;
      if (friendList == null || friendList.isEmpty) return MyMissionState();
      return await _fetchMyMissions(friendList);
    } catch (e) {
      debugPrint('MissionListNotifier.build Error: $e');
      return MyMissionState();
    }
  }

  Future<MyMissionState> _fetchMyMissions(
    List<FriendProfileEntity> friends,
  ) async {
    final repository = ref.read(missionsRepositoryProvider);
    final missionsData = await repository.fetchMyMissionsData();
    final allMissions = <MyMissionEntity>[];

    for (var missionData in missionsData) {
      final friendIds = List<String>.from(missionData['friend_ids'] ?? []);
      final friendProfiles =
          friends.where((f) => friendIds.contains(f.id)).toList();
      try {
        allMissions.add(
          MyMissionEntity(
            id: missionData['id'] as String,
            friendProfiles: friendProfiles,
            status: missionData['status'] as String,
            contentType: missionData['content_type'] as String,
            acceptDeadline: missionData['accept_deadline'] != null
                ? DateTime.parse(missionData['accept_deadline']).toLocal()
                : null,
            deadline:
                DateTime.parse(missionData['deadline'] as String).toLocal(),
            createdAt:
                DateTime.parse(missionData['created_at'] as String).toLocal(),
          ),
        );
      } catch (e) {
        debugPrint('Failed to parse mission: $e');
      }
    }

    return MyMissionState(
      allMissions: allMissions,
      pendingMyMissions: allMissions.where((m) => m.status == 'pending').toList(),
      acceptMyMissions: allMissions.where((m) => m.status == 'progressing').toList(),
      completeMyMissions: allMissions.where((m) => m.status == 'guessing').toList(),
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

class MissionCreateSelectionNotifier
    extends AutoDisposeNotifier<MissionCreateSelectionEntity> {
  @override
  MissionCreateSelectionEntity build() => MissionCreateSelectionEntity();

  void toggleSelection(FriendProfileEntity friendProfile) {
    final current = List<FriendProfileEntity>.from(state.selectedFriends);
    if (current.any((f) => f.id == friendProfile.id)) {
      current.removeWhere((f) => f.id == friendProfile.id);
    } else {
      current.add(friendProfile);
    }
    state = state.copyWith(selectedFriends: current);
  }

  bool isSelected(FriendProfileEntity friendProfile) {
    return state.selectedFriends.any((f) => f.id == friendProfile.id);
  }

  void updateSelectedFriends() {
    state = state.copyWith(selectedFriends: List.from(state.confirmedFriends));
  }

  void confirmSelection() {
    state = state.copyWith(confirmedFriends: List.from(state.selectedFriends));
  }

  void clearSelection() {
    state = state.copyWith(selectedFriends: [], confirmedFriends: []);
  }
}

class MissionCreationActionNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> createMission(
    int selectedScale,
    int selectedPeriod,
    int selectedType,
  ) async {
    final createSelectionState = ref.read(missionCreateSelectionProvider);
    final repository = ref.read(missionsRepositoryProvider);
    final List<String> friendIds =
        createSelectionState.confirmedFriends.map((f) => f.id).toList();
    final String contentType =
        selectedType == 0 ? 'daily' : (selectedType == 1 ? 'school' : 'work');

    final DateTime acceptDeadline;
    final DateTime deadline;
    if (selectedPeriod == 0) {
      acceptDeadline = DeadlineCalculator.calculateFutureTime(const Duration(hours: 1));
      deadline = DeadlineCalculator.calculateFutureTime(const Duration(days: 1));
    } else {
      acceptDeadline = DeadlineCalculator.calculateFutureTime(const Duration(hours: 3));
      deadline = DeadlineCalculator.calculateFutureTime(const Duration(days: 7));
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (selectedScale == 0) {
        await repository.createSingleMission(
          friendIds: friendIds,
          contentType: contentType,
          acceptDeadline: acceptDeadline,
          deadline: deadline,
        );
      } else {
        await repository.createGroupMission(
          friendIds: friendIds,
          contentType: contentType,
          deadline: deadline,
        );
      }
    });
  }
}

class MissionGroupRoomCreationActionNotifier
    extends AutoDisposeAsyncNotifier<String> {
  @override
  FutureOr<String> build() => '';

  Future<void> createGroupRoom(
    String title,
    int selectedType,
    int selectedPeriod,
  ) async {
    final repository = ref.read(missionsRepositoryProvider);
    final String contentType =
        selectedType == 0 ? 'daily' : (selectedType == 1 ? 'school' : 'work');
    final String limitTime = selectedPeriod == 0 ? '1' : '3';
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return repository.createGroupRoom(
        title: title,
        contentType: contentType,
        limitTime: limitTime,
      );
    });
  }
}

class MissionGuessNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> updateMissionGuess(String missionId, String text) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(missionsRepositoryProvider);
      await repository.updateMissionGuess(missionId, text);
    });
  }
}
