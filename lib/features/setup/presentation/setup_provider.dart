import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/models/models.dart';
import '../data/setup_repository.dart';

final setupRepositoryProvider = Provider<SetupRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return SetupRepository(supabase);
});

final myMemberRecordProvider =
    FutureProvider.autoDispose.family<RoomMemberModel?, String>((ref, roomId) async {
  final repo = ref.watch(setupRepositoryProvider);
  return repo.fetchMyMemberRecord(roomId);
});

final missionCandidatesProvider =
    FutureProvider.autoDispose.family<MissionCandidateModel?, int>((ref, roomMemberId) async {
  final repo = ref.watch(setupRepositoryProvider);
  return repo.fetchMissionCandidates(roomMemberId);
});

class MissionSetupState {
  final int? selectedMissionId;
  final bool isSubmitting;
  final bool isFinalized;
  final String? errorMessage;

  const MissionSetupState({
    this.selectedMissionId,
    this.isSubmitting = false,
    this.isFinalized = false,
    this.errorMessage,
  });

  MissionSetupState copyWith({
    int? selectedMissionId,
    bool? isSubmitting,
    bool? isFinalized,
    String? errorMessage,
  }) {
    return MissionSetupState(
      selectedMissionId: selectedMissionId ?? this.selectedMissionId,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isFinalized: isFinalized ?? this.isFinalized,
      errorMessage: errorMessage,
    );
  }
}

class MissionSetupNotifier extends StateNotifier<MissionSetupState> {
  final SetupRepository _repo;
  final Ref _ref;

  MissionSetupNotifier(this._repo, this._ref) : super(const MissionSetupState());

  void selectMission(int missionId) {
    if (state.isFinalized) return;
    state = state.copyWith(selectedMissionId: missionId);
  }

  Future<bool> confirmSelection(int roomMemberId, String roomId, [int? missionId]) async {
    if (state.isSubmitting || state.isFinalized) return true;

    final targetId = missionId ?? state.selectedMissionId;
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      await _repo.finalizeMission(roomMemberId, targetId);
      await _repo.checkAndStartOngoingGame(roomId);

      _ref.invalidate(myMemberRecordProvider(roomId));
      state = state.copyWith(isSubmitting: false, isFinalized: true);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: '미션 확정 실패: $e');
      return false;
    }
  }
}

final missionSetupProvider =
    StateNotifierProvider.autoDispose<MissionSetupNotifier, MissionSetupState>((ref) {
  final repo = ref.watch(setupRepositoryProvider);
  return MissionSetupNotifier(repo, ref);
});
