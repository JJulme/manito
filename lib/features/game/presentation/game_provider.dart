import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/models/models.dart';
import '../data/game_repository.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return GameRepository(supabase);
});

final myRecordProvider =
    FutureProvider.autoDispose.family<RecordModel?, (String, RecordType)>((ref, tuple) async {
  final (roomId, type) = tuple;
  final repo = ref.watch(gameRepositoryProvider);
  return repo.fetchMyRecord(roomId, type);
});

class GameRecordFormState {
  final bool isSaving;
  final String? errorMessage;
  final bool isSuccess;

  const GameRecordFormState({
    this.isSaving = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  GameRecordFormState copyWith({
    bool? isSaving,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return GameRecordFormState(
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class GameRecordFormNotifier extends StateNotifier<GameRecordFormState> {
  final GameRepository _repo;
  final Ref _ref;

  GameRecordFormNotifier(this._repo, this._ref) : super(const GameRecordFormState());

  Future<bool> save({
    required String roomId,
    required RecordType recordType,
    String? suspectUserId,
    required List<RecordBlock> content,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null, isSuccess: false);
    try {
      await _repo.saveRecord(
        roomId: roomId,
        recordType: recordType,
        suspectUserId: suspectUserId,
        content: content,
      );

      _ref.invalidate(myRecordProvider((roomId, recordType)));
      state = state.copyWith(isSaving: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final gameRecordFormProvider =
    StateNotifierProvider.autoDispose<GameRecordFormNotifier, GameRecordFormState>((ref) {
  final repo = ref.watch(gameRepositoryProvider);
  return GameRecordFormNotifier(repo, ref);
});
