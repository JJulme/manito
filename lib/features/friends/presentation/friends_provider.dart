import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/notifications/notification_sender.dart';
import '../../../core/providers.dart';
import '../../../core/models/models.dart';
import '../data/friends_repository.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final notificationSender = ref.watch(notificationSenderProvider);
  return FriendsRepository(supabase, notificationSender: notificationSender);
});

final acceptedFriendsProvider = FutureProvider.autoDispose<List<FriendshipModel>>((ref) async {
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.fetchAcceptedFriends();
});

final receivedFriendRequestsProvider = FutureProvider.autoDispose<List<FriendshipModel>>((ref) async {
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.fetchReceivedRequests();
});

/// 초대 가능한 친구 목록 필터링 Provider (검색어 및 기참여 멤버 제외)
final filteredInvitableFriendsProvider = Provider.autoDispose.family<
    List<FriendshipModel>,
    ({Set<String>? excludedUserIds, String searchQuery})>((ref, arg) {
  final friends = ref.watch(acceptedFriendsProvider).value ?? [];
  final currentUserId = ref.watch(currentUserProvider)?.id;

  return friends.where((f) {
    final friendId = f.friendProfile?.userId ??
        (f.requesterId == currentUserId ? f.receiverId : f.requesterId);
    if (arg.excludedUserIds != null && arg.excludedUserIds!.contains(friendId)) {
      return false;
    }
    if (arg.searchQuery.isEmpty) return true;
    final name = f.friendProfile?.name.toLowerCase() ?? '';
    final status = f.friendProfile?.statusMessage?.toLowerCase() ?? '';
    final code = f.friendProfile?.uniqueCode.toLowerCase() ?? '';
    final query = arg.searchQuery.toLowerCase();
    return name.contains(query) || status.contains(query) || code.contains(query);
  }).toList();
});

class FriendSearchState {
  final bool isLoading;
  final UserModel? foundUser;
  final FriendshipModel? existingFriendship;
  final String? errorMessage;

  const FriendSearchState({
    this.isLoading = false,
    this.foundUser,
    this.existingFriendship,
    this.errorMessage,
  });

  FriendSearchState copyWith({
    bool? isLoading,
    UserModel? foundUser,
    FriendshipModel? existingFriendship,
    String? errorMessage,
    bool clearFoundUser = false,
  }) {
    return FriendSearchState(
      isLoading: isLoading ?? this.isLoading,
      foundUser: clearFoundUser ? null : (foundUser ?? this.foundUser),
      existingFriendship: clearFoundUser ? null : (existingFriendship ?? this.existingFriendship),
      errorMessage: errorMessage,
    );
  }
}

class FriendSearchNotifier extends AutoDisposeNotifier<FriendSearchState> {
  late final FriendsRepository _repo;

  @override
  FriendSearchState build() {
    _repo = ref.watch(friendsRepositoryProvider);
    return const FriendSearchState();
  }

  Future<void> search(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.length != 8) {
      state = state.copyWith(
        clearFoundUser: true,
        errorMessage: '8자리 고유 코드를 입력해주세요.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _repo.searchUserByCode(cleanCode);
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          clearFoundUser: true,
          errorMessage: '일치하는 요원(사용자)을 찾을 수 없습니다.',
        );
        return;
      }

      final friendship = await _repo.getFriendship(user.userId);
      state = state.copyWith(
        isLoading: false,
        foundUser: user,
        existingFriendship: friendship,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearFoundUser: true,
        errorMessage: '검색 중 오류가 발생했습니다: $e',
      );
    }
  }

  Future<void> sendRequest(String receiverId) async {
    try {
      await _repo.sendFriendRequest(receiverId);
      final friendship = await _repo.getFriendship(receiverId);
      state = state.copyWith(existingFriendship: friendship);
    } catch (e) {
      state = state.copyWith(errorMessage: '요청 실패: $e');
    }
  }

  void reset() {
    state = const FriendSearchState();
  }
}

final friendSearchProvider =
    NotifierProvider.autoDispose<FriendSearchNotifier, FriendSearchState>(
  FriendSearchNotifier.new,
);
