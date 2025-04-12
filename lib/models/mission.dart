import 'package:intl/intl.dart';
import 'package:manito/models/user_profile.dart';

/// 내가 만든 미션 목록
class MyMission {
  final String id;
  final List<UserProfile> friendsProfile;
  final String status;
  final String deadlineType;
  final String? acceptDeadline;
  final String deadline;

  MyMission({
    required this.id,
    required this.friendsProfile,
    required this.status,
    required this.deadlineType,
    this.acceptDeadline,
    required this.deadline,
  });

  factory MyMission.fromJson(
    Map<String, dynamic> json,
    List<UserProfile> friendProfiles,
  ) {
    final DateFormat formatter = DateFormat('yy-MM-dd HH:mm:ss');
    String? acceptDeadlineFormatted = json['accept_deadline'] != null
        ? formatter.format(DateTime.parse(json['accept_deadline']))
        : null;
    return MyMission(
      id: json['id'],
      friendsProfile: friendProfiles,
      status: json['status'],
      deadlineType: json['deadline_type'],
      acceptDeadline: acceptDeadlineFormatted,
      deadline: formatter.format(DateTime.parse(json['deadline'])),
    );
  }
}

/// 미션 제안 상세
class MissionPropose {
  final String missionId;
  final List<String> randomContents;
  final String status;
  final String acceptDeadline;
  final String deadline;
  final String deadlineType;

  MissionPropose({
    required this.missionId,
    required this.randomContents,
    required this.status,
    required this.acceptDeadline,
    required this.deadline,
    required this.deadlineType,
  });

  factory MissionPropose.fromJson(Map<String, dynamic> json) {
    // Missions 데이터를 맵핑
    final missions = json['missions'];
    final DateFormat formatter = DateFormat('yy-MM-dd HH:mm:ss');
    return MissionPropose(
      missionId: json['mission_id'],
      randomContents: List<String>.from(json['random_contents']),
      status: missions['status'],
      acceptDeadline:
          formatter.format(DateTime.parse(missions['accept_deadline'])),
      deadline: formatter.format(DateTime.parse(missions['deadline'])),
      deadlineType: missions['deadline_type'],
    );
  }
}

/// 미션 제안 리스트
class MissionProposeList {
  final String id;
  final String creatorId;
  final String acceptDeadline;

  MissionProposeList({
    required this.id,
    required this.creatorId,
    required this.acceptDeadline,
  });

  factory MissionProposeList.fromJson(Map<String, dynamic> json) {
    // Missions 데이터를 맵핑
    final missions = json['missions'];
    final DateFormat formatter = DateFormat('yy-MM-dd HH:mm:ss');
    return MissionProposeList(
      id: json['id'],
      creatorId: missions['creator_id'],
      acceptDeadline:
          formatter.format(DateTime.parse(missions['accept_deadline'])),
    );
  }
}

/// 내가 수락한 미션 내용
class MissionAccept {
  final String missionId;
  final String creatorId;
  final String content;
  final String status;
  final String deadline;
  final String deadlineType;

  MissionAccept({
    required this.missionId,
    required this.creatorId,
    required this.content,
    required this.status,
    required this.deadline,
    required this.deadlineType,
  });

  factory MissionAccept.fromJson(Map<String, dynamic> json) {
    final missions = json['missions'];
    final DateFormat formatter = DateFormat('yy-MM-dd HH:mm:ss');
    return MissionAccept(
      missionId: json['id'],
      creatorId: missions['creator_id'],
      content: json['content'],
      status: json['status'],
      deadline: formatter.format(DateTime.parse(missions['deadline'])),
      deadlineType: missions['deadline_type'],
    );
  }
}

/// 미션하고 작성하는 게시물
class MissionPost {
  final String? description;
  final List<String>? imageUrlList;

  MissionPost({
    this.description,
    this.imageUrlList,
  });

  factory MissionPost.fromJson(Map<String, dynamic> json) {
    // 자동 응답에서 가져오는 경우 리스트 변환
    var imageUrls = json['image_url_list'];
    List<String>? imageUrlList;
    if (imageUrls is List) {
      imageUrlList = List<String>.from(imageUrls);
    } else if (imageUrls != null) {
      imageUrlList = [imageUrls];
    }
    return MissionPost(
      description: json['description'] as String?,
      imageUrlList: imageUrlList,
    );
  }
}
