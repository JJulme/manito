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
    if (json['users'] is Map<String, dynamic>) {
      profile = UserModel.fromJson(json['users'] as Map<String, dynamic>);
    } else if (json['requester'] is Map<String, dynamic> &&
        json['receiver'] is Map<String, dynamic> &&
        currentUserId != null) {
      final isRequester = json['requester_id'] == currentUserId;
      profile = UserModel.fromJson(
        (isRequester ? json['receiver'] : json['requester']) as Map<String, dynamic>,
      );
    }

    return FriendshipModel(
      friendshipId: (json['friendship_id'] as num?)?.toInt() ?? 0,
      requesterId: json['requester_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      status: FriendshipStatus.fromString(json['status']?.toString() ?? ''),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal()
          : null,
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
