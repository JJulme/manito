import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/utils/logger.dart';
import 'package:manito/features_new/friends/domain/repositories/repository_provider.dart';
import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';

// ========== State ==========
class UserSearchState {
  final String query;
  final UserEntity? searchedUser;
  final bool isLoading; // 로딩 상태 추가

  const UserSearchState({
    this.query = '',
    this.searchedUser,
    this.isLoading = false,
  });

  // UI에서 쓰기 편한 상태 판단 로직
  bool get isInitial => query.isEmpty && !isLoading;
  bool get noResult => query.isNotEmpty && searchedUser == null && !isLoading;

  UserSearchState copyWith({
    String? query,
    UserEntity? Function()? searchedUser, // null 처리를 위한 또 다른 현대적 방법
    bool? isLoading,
  }) {
    return UserSearchState(
      query: query ?? this.query,
      searchedUser: searchedUser != null ? searchedUser() : this.searchedUser,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ========== Provider ==========
final userSearchProvider =
    NotifierProvider.autoDispose<UserSearchNotifier, UserSearchState>(() {
      return UserSearchNotifier();
    });

// ========== Notifier ==========
class UserSearchNotifier extends AutoDisposeNotifier<UserSearchState> {
  @override
  UserSearchState build() => const UserSearchState();

  // 1. 유저 검색 로직
  Future<void> searchUser(String email) async {
    // 검색 시작: 로딩 켜고, 쿼리 저장, 이전 결과 초기화
    state = state.copyWith(
      query: email,
      isLoading: true,
      searchedUser: () => null,
    );

    try {
      final repository = ref.read(friendsRepositoryProvider);
      final user = await repository.searchUserByEmail(email);

      state = state.copyWith(searchedUser: () => user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      Log.e('$e');
      rethrow; // UI에서 catch하여 토스트를 띄울 수 있게 던짐
    }
  }

  // 2. 친구 요청 로직
  Future<String> requestFriend(String targetId) async {
    // 요청은 상태 변화(loading)보다는 결과값이 중요하므로 바로 호출
    try {
      final repository = ref.read(friendsRepositoryProvider);
      final result = await repository.sendFriendRequest(targetId);
      return result;
    } catch (e) {
      Log.e('$e');
      rethrow;
    }
  }

  // 검색 초기화 (화면을 나갈 때 호출)
  void clearSearch() {
    state = const UserSearchState();
  }
}
