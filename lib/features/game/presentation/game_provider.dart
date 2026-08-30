import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/models/models.dart';
import '../../../core/util/app_logger.dart';
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

class GameRecordFormNotifier extends AutoDisposeNotifier<GameRecordFormState> {
  late final GameRepository _repo;

  @override
  GameRecordFormState build() {
    _repo = ref.watch(gameRepositoryProvider);
    return const GameRecordFormState();
  }

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

      ref.invalidate(myRecordProvider((roomId, recordType)));
      state = state.copyWith(isSaving: false, isSuccess: true);
      return true;
    } catch (e, s) {
      AppLogger.e('게임 기록 저장 실패', error: e, stackTrace: s);
      state = state.copyWith(
        isSaving: false,
        errorMessage: '기록 저장에 실패했습니다. 다시 시도해 주세요.',
      );
      return false;
    }
  }
}

final gameRecordFormProvider =
    NotifierProvider.autoDispose<GameRecordFormNotifier, GameRecordFormState>(
  GameRecordFormNotifier.new,
);
