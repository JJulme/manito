import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ProfileRepository(supabase);
});

class ProfileFormState {
  final bool isSaving;
  final String? errorMessage;
  final bool saveSuccess;

  const ProfileFormState({
    this.isSaving = false,
    this.errorMessage,
    this.saveSuccess = false,
  });

  ProfileFormState copyWith({
    bool? isSaving,
    String? errorMessage,
    bool? saveSuccess,
  }) {
    return ProfileFormState(
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      saveSuccess: saveSuccess ?? this.saveSuccess,
    );
  }
}

class ProfileFormNotifier extends StateNotifier<ProfileFormState> {
  final ProfileRepository _repo;
  final Ref _ref;

  ProfileFormNotifier(this._repo, this._ref) : super(const ProfileFormState());

  Future<bool> saveProfile({
    String? name,
    String? statusMessage,
    String? profileImageUrl,
    String? manitoAutoReplyText,
    String? manitoAutoReplyImg,
    String? guessAutoReplyText,
    String? guessAutoReplyImg,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null, saveSuccess: false);
    try {
      await _repo.updateProfile(
        name: name,
        statusMessage: statusMessage,
        profileImageUrl: profileImageUrl,
        manitoAutoReplyText: manitoAutoReplyText,
        manitoAutoReplyImg: manitoAutoReplyImg,
        guessAutoReplyText: guessAutoReplyText,
        guessAutoReplyImg: guessAutoReplyImg,
      );
      // Refresh current user profile provider
      _ref.invalidate(currentUserProfileProvider);
      state = state.copyWith(isSaving: false, saveSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: '저장 실패: $e');
      return false;
    }
  }
}

final profileFormProvider =
    StateNotifierProvider.autoDispose<ProfileFormNotifier, ProfileFormState>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileFormNotifier(repo, ref);
});
