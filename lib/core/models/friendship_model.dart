import 'user_model.dart';

enum FriendshipStatus {
  requested('REQUESTED'),
  accepted('ACCEPTED'),
  blocked('BLOCKED');

  final String value;
  const FriendshipStatus(this.value);

  static FriendshipStatus fromString(String val) {
    return FriendshipStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => FriendshipStatus.requested,
    );
  }
}

class FriendshipModel {
  final int friendshipId;
  final String requesterId;
  final String receiverId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final UserModel? friendProfile;

  const FriendshipModel({
    required this.friendshipId,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.friendProfile,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    UserModel? profile;
    if (json['users'] != null) {
      profile = UserModel.fromJson(json['users'] as Map<String, dynamic>);
    } else if (json['requester'] != null && json['receiver'] != null && currentUserId != null) {
      final isRequester = json['requester_id'] == currentUserId;
      profile = UserModel.fromJson(
        (isRequester ? json['receiver'] : json['requester']) as Map<String, dynamic>,
      );
    }

    return FriendshipModel(
      friendshipId: json['friendship_id'] as int,
      requesterId: json['requester_id'] as String,
      receiverId: json['receiver_id'] as String,
      status: FriendshipStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      friendProfile: profile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'friendship_id': friendshipId,
      'requester_id': requesterId,
      'receiver_id': receiverId,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
