import 'package:manito/models/user_profile.dart';

/// 내가 만든 미션 목록 모델
///
/// 이 클래스는 사용자가 생성한 미션 정보를 나타냅니다.
/// 미션의 상태, 미션 기한, 수락 기한 그리고 미션제안을 받은 친구들의 프로필을 포함합니다.
///
/// 모든 필드는 미션의 현재 상태를 정확히 반영하며,
class MyMission {
  /// 미션의 고유 식별자 (ID).
  /// 이 필드는 필수이며, 미션 데이터의 조회 및 관리에 사용됩니다.
  final String id;

  /// 미션 제안을 받은 친구들의 프로필 리스트.
  /// [FriendProfile] 객체들로 구성되며, 미션 제안을 받은 사용자 프로필을 제공합니다.
  /// 이 리스트는 JSON 데이터 내부에서 직접 파싱되지 않고, `fromJson` 팩토리 생성자 외부에서
  /// 미리 파싱되어 주입됩니다.
  /// 이 필드는 필수입니다.
  final List<FriendProfile> friendsProfile;

  /// 미션의 현재 상태.
  /// 이 모델에서는 전체 4가지(대기중, 진행중, 추측중, 완료)의 상태 중 3가지(대기중, 진행중, 완료)의 상태를 받음.
  /// 이 필드는 필수입니다.
  final String status;

  /// 미션의 유형.
  /// 일상, 학교, 직장.
  /// 이 필드는 필수입니다.
  final String contentType;

  /// 미션 수락 마감 기한.
  /// 사용자가 미션을 수락해야 하는 최종 시간을 나타냅니다.
  /// 수락 기한까지 수락한 친구가 없을 경우 자동으로 삭제됩니다.
  /// 친구 중 한명이 수락을 하게 되면 `null`이 됩니다.
  final DateTime? acceptDeadline;

  /// 미션의 최종 마감 기한.
  /// 미션이 완료되어야 하는 최종 시간을 나타냅니다.
  /// 이 필드는 필수입니다.
  final DateTime deadline;

  /// 새로운 [MyMission] 인스턴스를 생성합니다.
  ///
  /// [id], [friendsProfile], [status], [deadlineType], [deadline]은 미션을 정의하는
  /// 필수 필드입니다. [acceptDeadline]은 선택 사항입니다.
  MyMission({
    required this.id,
    required this.friendsProfile,
    required this.status,
    required this.contentType,
    this.acceptDeadline,
    required this.deadline,
  });

  /// JSON [Map]으로부터 [MyMission] 인스턴스를 생성하는 팩토리 생성자.
  ///
  /// [json]: API 응답으로 받은 미션의 JSON 데이터 맵입니다.
  /// [friendProfiles]: 이 미션과 관련된 친구 프로필의 미리 파싱된 리스트입니다.
  ///                   이 리스트는 `json` 데이터 내부에 직접 포함되어 있지 않으므로,
  ///                   팩토리 메서드 외부에서 생성되어 인자로 주입되어야 합니다.
  factory MyMission.fromJson(
    Map<String, dynamic> json,
    List<FriendProfile> friendProfiles,
  ) {
    return MyMission(
      id: json['id'] as String,
      friendsProfile: friendProfiles,
      status: json['status'] as String,
      contentType: json['content_type'] as String,
      acceptDeadline:
          json['accept_deadline'] != null
              ? DateTime.parse(json['accept_deadline'] as String).toLocal()
              : null,
      deadline: DateTime.parse(json['deadline'] as String).toLocal(),
    );
  }
}

/// 미션 제안 상세
///
/// 특정 미션 제안에 대한 상세 정보를 담고 있는 데이터 클래스입니다.
/// 미션 ID, 랜덤 미션 리스트, 미션 상태, 수락 기한, 미션 기한
/// 그리고 미션 기한 유형과 같은 필수 정보를 포함합니다.
class MissionPropose {
  /// 미션제안과 연결된 미션의 고유 식별자 (ID).
  /// 이 필드는 필수입니다.
  final String missionId;

  /// 포함된 랜덤 미션 콘텐츠 문자열 리스트.
  /// (예: 미션 설명의 대체 텍스트, 힌트 등). 이 필드는 필수입니다.
  final List<MissionContent> randomContents;

  /// 미션 수락 마감 기한.
  /// 이 필드는 필수입니다.
  final DateTime acceptDeadline;

  /// 미션의 최종 마감 기한.
  /// 이 필드는 필수입니다.
  final DateTime deadline;

  /// 미션의 마감 기한 유형. (하루, 한주)
  /// 이 필드는 필수입니다.
  final String contentType;

  /// 새로운 [MissionPropose] 인스턴스를 생성합니다.
  ///
  /// 모든 매개변수는 필수입니다.
  MissionPropose({
    required this.missionId,
    required this.randomContents,
    required this.acceptDeadline,
    required this.deadline,
    required this.contentType,
  });

  /// JSON [Map]으로부터 [MissionPropose] 인스턴스를 생성하는 팩토리 생성자.
  ///
  /// [json]: API 응답으로 받은 JSON 데이터 맵입니다.
  ///
  /// JSON 구조에 따라 `mission_id`와 `random_contents`는 최상위 레벨에서,
  /// 나머지 필드들은 `json['missions']`라는 중첩된 맵에서 파싱됩니다.
  factory MissionPropose.fromJson(Map<String, dynamic> json) {
    // 'missions' 키가 존재하고 Map<String, dynamic> 타입인지 확인
    final missions = json['missions'] as Map<String, dynamic>;
    return MissionPropose(
      missionId: json['mission_id'] as String,
      randomContents: json['random_contents'],
      acceptDeadline:
          DateTime.parse(missions['accept_deadline'] as String).toLocal(),
      deadline: DateTime.parse(missions['deadline'] as String).toLocal(),
      contentType: missions['content_type'] as String,
    );
  }
}

/// 미션 제안 리스트
///
/// 미션 제안 리스트에서 각 항목의 간략한 정보를 나타냅니다.
/// 이 모델은 미션제안의 고유 ID, 생성자 ID, 그리고 수락 마감 기한을 포함합니다.
class MissionProposeList {
  /// 미션 제안의 고유 식별자 (ID).
  /// 이 필드는 필수입니다. (JSON 최상위 `id`와 맵핑)
  final String id;

  /// 미션 제안을 생성한 사용자의 ID.
  /// 이 필드는 필수입니다. (JSON의 `missions` 맵 내부 `creator_id`와 맵핑)
  final String creatorId;

  /// 미션 수락 마감 기한 (UTC).
  /// [DateTime] 객체로 저장되며, 이 필드는 필수입니다.
  /// (JSON의 `missions` 맵 내부 `accept_deadline`과 맵핑)
  final DateTime acceptDeadline;

  /// 새로운 [MissionProposeList] 인스턴스를 생성합니다.
  ///
  /// 모든 매개변수는 필수입니다.
  MissionProposeList({
    required this.id,
    required this.creatorId,
    required this.acceptDeadline,
  });

  /// JSON [Map]으로부터 [MissionProposeList] 인스턴스를 생성하는 팩토리 생성자.
  ///
  /// [json]: API 응답으로 받은 JSON 데이터 맵입니다.
  ///
  /// JSON 구조에 따라 `id`는 최상위 레벨에서,
  /// `creator_id`와 `accept_deadline`은 `json['missions']`라는 중첩된 맵에서 파싱됩니다.
  factory MissionProposeList.fromJson(Map<String, dynamic> json) {
    // 'missions' 키가 존재하고 Map<String, dynamic> 타입인지 확인
    final Map<String, dynamic> missions =
        json['missions'] as Map<String, dynamic>;
    return MissionProposeList(
      id: json['id'] as String,
      creatorId: missions['creator_id'] as String,
      acceptDeadline:
          DateTime.parse(missions['accept_deadline'] as String).toLocal(),
    );
  }
}

/// 내가 수락한 미션 내용 모델
///
/// 사용자가 수락한 미션의 상세 내용을 나타냅니다.
/// 미션의 ID, 생성자 ID, 미션 내용, 현재 상태, 미션 기한,
/// 그리고 미션 기한 유형과 같은 필수 정보를 포함합니다.
class MissionAccept {
  /// 미션의 고유 식별자 (ID).
  /// JSON의 'id' 필드와 맵핑됩니다. 이 필드는 필수입니다.
  final String id;

  /// 미션을 생성한 사용자의 ID.
  /// 이 필드는 필수입니다.
  final String creatorId;

  /// 미션의 구체적인 내용.
  /// 마니또 사용자가 수행해야 할 미션 지시사항 입니다. 이 필드는 필수입니다.
  final String content;

  /// 미션의 현재 상태.
  /// 4가지의 상태중에 '진행중' 만 가져옵니다.
  /// 이 필드는 필수입니다.
  final String status;

  /// 미션의 최종 마감 기한 (UTC).
  /// [DateTime] 객체로 저장되며, 이 필드는 필수입니다.
  final DateTime deadline;

  /// 미션의 마감 기한 유형.
  /// (예: 하루, 한주). 이 필드는 필수입니다.
  final String contentType;

  /// 새로운 [MissionAccept] 인스턴스를 생성합니다.
  ///
  /// 모든 매개변수는 필수입니다.
  MissionAccept({
    required this.id,
    required this.creatorId,
    required this.content,
    required this.status,
    required this.deadline,
    required this.contentType,
  });

  /// JSON [Map]으로부터 [MissionAccept] 인스턴스를 생성하는 팩토리 생성자.
  ///
  /// [json]: API 응답으로 받은 JSON 데이터 맵입니다.
  ///
  /// 모든 필드는 JSON 데이터의 최상위 레벨에서 직접 파싱됩니다.
  factory MissionAccept.fromJson(Map<String, dynamic> json) {
    return MissionAccept(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      content: json['content'] as String,
      status: json['status'] as String,
      deadline: DateTime.parse(json['deadline'] as String).toLocal(),
      contentType: json['content_type'] as String,
    );
  }
}

/// 마니또가 미션을 완료, 생성자가 추측을 미완료한 내용을 불러오는 모델
///
/// 생성자의 id만 가져옵니다.
/// ???가 추측중입니다 로 보여짐
class MissionGuess {
  final String creatorId;

  MissionGuess({required this.creatorId});

  factory MissionGuess.fromJson(Map<String, dynamic> json) {
    return MissionGuess(creatorId: json['creator_id'] as String);
  }
}

/// 미션하고 작성했던 내용을 불러오는 모델
///
/// 마니또가 미션과 관련하여 임시저장 했던 콘텐츠를 나타냅니다.
/// 설명과 첨부 이미지 URL 리스트를 포함합니다.
class MissionPost {
  /// 게시물의 상세 설명 또는 내용.
  /// 사용자가 작성한 텍스트를 포함하며, 없을 경우 `null`이 될 수 있습니다.
  final String? description;

  /// 게시물에 첨부된 이미지 URL들의 리스트.
  /// 이미지가 없는 경우 `null`이 될 수 있으며, 리스트 내의 각 URL은 `String` 타입입니다.
  final List<String>? imageUrlList;

  /// 새로운 [MissionPost] 인스턴스를 생성합니다.
  ///
  /// 모든 필드는 선택 사항이며 `null`을 허용합니다.
  MissionPost({this.description, this.imageUrlList});

  /// JSON [Map]으로부터 [MissionPost] 인스턴스를 생성하는 팩토리 생성자.
  ///
  /// [json]: API 응답으로 받은 JSON 데이터 맵입니다.
  ///
  /// `image_url_list`는 리스트 형태이며, `null`이거나 리스트가 아닌 경우 `[]`로 파싱됩니다.
  factory MissionPost.fromJson(Map<String, dynamic> json) {
    // 자동 응답에서 가져오는 경우 리스트 변환
    List<String>? imageUrlList;

    // 문자열을 리스트로 변환
    var parsed = json['image_url_list'];
    if (parsed is List) {
      imageUrlList =
          parsed
              .where((item) => item != null)
              .map((item) => item.toString())
              .toList();
    }
    // null 일 경우
    else {
      imageUrlList = [];
    }

    return MissionPost(
      description: json['description'] as String,
      imageUrlList: imageUrlList,
    );
  }
}

class MissionContent {
  final String id;
  final String content;

  MissionContent({required this.id, required this.content});

  factory MissionContent.fromJson(Map<String, dynamic> json) {
    return MissionContent(
      id: json['id'] as String,
      content: json['content'] as String,
    );
  }
}
