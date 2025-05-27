/// 사용자 프로필 모델
///
/// 애플리케이션 내 사용자의 프로필 정보를 나타냅니다.
/// 사용자 ID, 이메일, 닉네임과 같은 필수 정보와 함께,
/// 상태 메시지 및 프로필 이미지 URL과 같은 선택적 정보를 포함합니다.
class UserProfile {
  /// 사용자의 고유 식별자 (ID).
  /// 친구와 자신을 구분할 때 사용됩니다.
  /// 이 필드는 필수입니다.
  String id;

  /// 사용자의 이메일 주소.
  /// 이메일로 친구 찾기화면에서 사용됩니다.
  /// 이 필드는 필수입니다.
  String email;

  /// 사용자의 닉네임. 이 필드는 필수입니다.
  String nickname;

  /// 사용자의 상태 메시지.
  /// 없을 경우 빈 문자열(`''`)이 기본값으로 설정됩니다. 이 필드는 필수입니다.
  String statusMessage;

  /// 사용자의 프로필 이미지 URL.
  /// 프로필 이미지가 없을 경우 `null`이 될 수 있습니다.
  String? profileImageUrl;

  /// 새로운 [UserProfile] 인스턴스를 생성합니다.
  ///
  /// [id], [email], [nickname]은 필수 매개변수입니다.
  /// [statusMessage]는 기본적으로 빈 문자열이며, [profileImageUrl]은 `null`일 수 있습니다.
  UserProfile({
    required this.id,
    required this.email,
    required this.nickname,
    this.statusMessage = '',
    this.profileImageUrl,
  });

  /// JSON [Map]으로부터 [UserProfile] 인스턴스를 생성하는 팩토리 생성자.
  ///
  /// [json]: API 응답으로 받은 JSON 데이터 맵입니다.
  ///
  /// `id`, `email`, `nickname`은 `String`으로 명시적 캐스팅됩니다.
  /// `status_message`는 `null`이거나 없을 경우 빈 문자열로,
  /// `profile_image_url`은 없을 경우 `null`로 처리됩니다.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      statusMessage: json['status_message'] as String,
      profileImageUrl: json['profile_image_url'] as String,
    );
  }
}

/// 친구 프로필 모델
///
/// 애플리케이션 내 친구의 프로필 정보를 나타냅니다.
/// 사용자 설정 닉네임, 친구 ID, 친구 설정 닉네임, 상태 메시지, 프로필 이미지 URL과 같은 정보를 포함합니다.
/// 닉네임은 'friend_nickname'(사용자 설정 닉네임) 필드를 우선적으로 사용하여 사용자 지정 닉네임을 지원합니다.
class FriendProfile {
  /// 친구의 고유 식별자 (ID). 이 필드는 필수입니다.
  /// JSON의 'profiles' 객체 내 'id' 필드와 맵핑됩니다.
  final String id;

  /// 친구의 닉네임. 이 필드는 필수입니다.
  /// 'friend_nickname' 필드(사용자 지정 닉네임)가 유효할 경우 이를 사용하고,
  /// 그렇지 않을 경우 'profiles' 객체 내의 'nickname'을 사용합니다.
  final String nickname;

  /// 친구의 상태 메시지.
  /// 'profiles' 객체 내의 'status_message' 필드와 맵핑됩니다. `null`일 수 있습니다.
  final String? statusMessage;

  /// 친구의 프로필 이미지 URL.
  /// 'profiles' 객체 내의 'profile_image_url' 필드와 맵핑됩니다. `null`일 수 있습니다.
  final String? profileImageUrl;

  /// 새로운 [FriendProfile] 인스턴스를 생성합니다.
  ///
  /// [id]와 [nickname]은 필수 매개변수입니다.
  /// [statusMessage]와 [profileImageUrl]은 선택 사항이며 `null`을 허용합니다.
  FriendProfile({
    required this.id,
    required this.nickname,
    this.statusMessage,
    this.profileImageUrl,
  });

  /// JSON [Map]으로부터 [FriendProfile] 인스턴스를 생성하는 팩토리 생성자.
  ///
  /// [json]: API 응답으로 받은 JSON 데이터 맵입니다.
  /// 이 맵은 'profiles'라는 중첩된 맵을 포함하며, 'friend_nickname'은 최상위 레벨에 있습니다.
  factory FriendProfile.fromJson(Map<String, dynamic> json) {
    // 'profiles' 키가 존재하고 Map<String, dynamic> 타입인지 안전하게 확인합니다.
    // 만약 'profiles'가 없거나 Map이 아니면 빈 맵으로 처리하여 NullPointerException 방지
    final Map<String, dynamic> profileJson =
        (json['profiles'] as Map<String, dynamic>?) ?? {};

    // 1. profiles 객체 내의 실제 닉네임을 먼저 가져옵니다.
    final String actualNickname =
        (profileJson['nickname'] as String?) ?? '알수없음';
    // 2. friend_nickname 값을 가져옵니다.
    final String? rawFriendNickname = json['friend_nickname'] as String?;
    // 3. rawFriendNickname이 유효한지(null이 아니고, 비어있지 않으며, 공백만으로 이루어지지 않았는지) 확인합니다.
    final bool isFriendNicknameValid =
        rawFriendNickname?.trim().isNotEmpty == true;

    return FriendProfile(
      id: (profileJson['id'] as String?) ?? 'unknown_id',
      nickname: isFriendNicknameValid ? rawFriendNickname! : actualNickname,
      statusMessage: profileJson['status_message'] as String?,
      profileImageUrl: profileJson['profile_image_url'] as String?,
    );
  }
}
