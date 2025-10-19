import 'package:manito/features/profiles/profile.dart';

class FriendSearchState {
  final String query;
  final UserProfile? friendProfile;
  final bool isLoading;
  final bool isSearching;
  final String? message;
  final String? error;
  const FriendSearchState({
    this.query = '',
    this.friendProfile,
    this.isLoading = false,
    this.isSearching = false,
    this.message,
    this.error,
  });

  bool get hasResult => friendProfile != null;
  bool get hasError => error != null;
  bool get isEmpty => friendProfile == null && !isSearching;
  bool get noResult => friendProfile == null && isSearching;

  FriendSearchState copyWith({
    String? query,
    // null 설정
    Object? friendProfile = _noChange,
    bool? isLoading,
    bool? isSearching,
    String? message,
    String? error,
  }) {
    return FriendSearchState(
      query: query ?? this.query,
      // null 설정 가능
      friendProfile:
          friendProfile == _noChange
              ? this.friendProfile
              : friendProfile as UserProfile?,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      message: message ?? this.message,
      error: error ?? this.error,
    );
  }

  static const _noChange = Object();
}

class FriendRequestState {
  final List<UserProfile> requestUserList;
  final bool isLoading;
  final String? error;
  FriendRequestState({
    this.requestUserList = const [],
    this.isLoading = false,
    this.error,
  });

  FriendRequestState copyWith({
    List<UserProfile>? requestUserList,
    bool? isLoading,
    String? error,
  }) {
    return FriendRequestState(
      requestUserList: requestUserList ?? this.requestUserList,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class BlacklistState {
  final List<UserProfile> blackList;
  final bool isLoading;
  final String? error;

  BlacklistState({
    this.blackList = const [],
    this.isLoading = false,
    this.error,
  });

  BlacklistState copyWith({
    List<UserProfile>? blackList,
    bool? isLoading,
    String? error,
  }) {
    return BlacklistState(
      blackList: blackList ?? this.blackList,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FriendEditState {
  final bool isLoading;
  final String? error;
  FriendEditState({this.isLoading = false, this.error});

  FriendEditState copyWith({bool? isLoading, String? error}) {
    return FriendEditState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
