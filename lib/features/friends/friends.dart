import 'package:manito/features/profiles/profile.dart';

class FriendSearchState {
  final String query;
  final UserProfile? friendProfile;

  const FriendSearchState({this.query = '', this.friendProfile});

  bool get hasResult => friendProfile != null;
  bool get isEmpty => friendProfile == null && query.isEmpty;
  bool get noResult => friendProfile == null && query.isNotEmpty;

  FriendSearchState copyWith({
    String? query,
    Object? friendProfile = _noChange,
  }) {
    return FriendSearchState(
      query: query ?? this.query,
      friendProfile:
          friendProfile == _noChange
              ? this.friendProfile
              : friendProfile as UserProfile?,
    );
  }

  static const _noChange = Object();
}

class FriendRequestState {
  final List<UserProfile> requestUserList;
  FriendRequestState({this.requestUserList = const []});

  FriendRequestState copyWith({List<UserProfile>? requestUserList}) {
    return FriendRequestState(
      requestUserList: requestUserList ?? this.requestUserList,
    );
  }
}

class BlacklistState {
  final List<UserProfile> blackList;

  BlacklistState({this.blackList = const []});

  BlacklistState copyWith({List<UserProfile>? blackList}) {
    return BlacklistState(blackList: blackList ?? this.blackList);
  }
}
