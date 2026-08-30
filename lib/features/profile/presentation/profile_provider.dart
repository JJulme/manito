import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/util/app_logger.dart';
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

class ProfileFormNotifier extends AutoDisposeNotifier<ProfileFormState> {
  late final ProfileRepository _repo;

  @override
  ProfileFormState build() {
    _repo = ref.watch(profileRepositoryProvider);
    return const ProfileFormState();
  }

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
      ref.invalidate(currentUserProfileProvider);
      state = state.copyWith(isSaving: false, saveSuccess: true);
      return true;
    } catch (e, s) {
      AppLogger.e('프로필 저장 실패', error: e, stackTrace: s);
      state = state.copyWith(isSaving: false, errorMessage: '프로필 저장에 실패했습니다. 다시 시도해 주세요.');
      return false;
    }
  }
}

final profileFormProvider =
    NotifierProvider.autoDispose<ProfileFormNotifier, ProfileFormState>(
  ProfileFormNotifier.new,
);
