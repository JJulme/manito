class UserModel {
  final String userId;
  final String uniqueCode;
  final String name;
  final String? profileImageUrl;
  final String? statusMessage;
  final String? manitoAutoReplyText;
  final String? manitoAutoReplyImg;
  final String? guessAutoReplyText;
  final String? guessAutoReplyImg;
  final DateTime createdAt;

  const UserModel({
    required this.userId,
    required this.uniqueCode,
    required this.name,
    this.profileImageUrl,
    this.statusMessage,
    this.manitoAutoReplyText,
    this.manitoAutoReplyImg,
    this.guessAutoReplyText,
    this.guessAutoReplyImg,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as String,
      uniqueCode: json['unique_code'] as String,
      name: json['name'] as String,
      profileImageUrl: json['profile_image_url'] as String?,
      statusMessage: json['status_message'] as String?,
      manitoAutoReplyText: json['manito_auto_reply_text'] as String?,
      manitoAutoReplyImg: json['manito_auto_reply_img'] as String?,
      guessAutoReplyText: json['guess_auto_reply_text'] as String?,
      guessAutoReplyImg: json['guess_auto_reply_img'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'unique_code': uniqueCode,
      'name': name,
      'profile_image_url': profileImageUrl,
      'status_message': statusMessage,
      'manito_auto_reply_text': manitoAutoReplyText,
      'manito_auto_reply_img': manitoAutoReplyImg,
      'guess_auto_reply_text': guessAutoReplyText,
      'guess_auto_reply_img': guessAutoReplyImg,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    String? profileImageUrl,
    String? statusMessage,
    String? manitoAutoReplyText,
    String? manitoAutoReplyImg,
    String? guessAutoReplyText,
    String? guessAutoReplyImg,
  }) {
    return UserModel(
      userId: userId,
      uniqueCode: uniqueCode,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      statusMessage: statusMessage ?? this.statusMessage,
      manitoAutoReplyText: manitoAutoReplyText ?? this.manitoAutoReplyText,
      manitoAutoReplyImg: manitoAutoReplyImg ?? this.manitoAutoReplyImg,
      guessAutoReplyText: guessAutoReplyText ?? this.guessAutoReplyText,
      guessAutoReplyImg: guessAutoReplyImg ?? this.guessAutoReplyImg,
      createdAt: createdAt,
    );
  }

  /// 5가지 필수 정보가 모두 채워져 있는지 확인
  bool get isProfileComplete {
    final hasImage = profileImageUrl != null && profileImageUrl!.trim().isNotEmpty;
    final hasName = name.trim().isNotEmpty;
    final hasStatus = statusMessage != null && statusMessage!.trim().isNotEmpty;
    final hasManitoReply = manitoAutoReplyText != null && manitoAutoReplyText!.trim().isNotEmpty;
    final hasGuessReply = guessAutoReplyText != null && guessAutoReplyText!.trim().isNotEmpty;

    return hasImage && hasName && hasStatus && hasManitoReply && hasGuessReply;
  }
}
