// ========== Model ==========
import 'package:manito/features/profiles/profile.dart';
import 'package:photo_manager/photo_manager.dart';

class ManitoPropose {
  // 항상 있는 필드
  final String id;
  final String creatorId;
  final DateTime acceptDeadline;

  // 상세정보 필드
  final String? missionId;
  final List<ManitoContent>? randomContents;
  final String? contentType;
  final DateTime? deadline;

  const ManitoPropose({
    required this.id,
    required this.creatorId,
    required this.acceptDeadline,
    this.missionId,
    this.randomContents,
    this.contentType,
    this.deadline,
  });

  bool get isDetailLoaded {
    return missionId != null &&
        randomContents != null &&
        contentType != null &&
        deadline != null;
  }

  factory ManitoPropose.fromJson(Map<String, dynamic> json) {
    return ManitoPropose(
      id: json['id'] as String,
      creatorId: json['missions']['creator_id'] as String,
      acceptDeadline: DateTime.parse(
        json['missions']['accept_deadline'] as String,
      ),
    );
  }

  factory ManitoPropose.fromDetailJson(Map<String, dynamic> json) {
    final missionsData = json['missions'] as Map<String, dynamic>;
    return ManitoPropose(
      id: json['id'] as String,
      missionId: json['mission_id'] as String,
      creatorId: missionsData['creator_id'] as String,
      acceptDeadline: DateTime.parse(missionsData['accept_deadline'] as String),
      randomContents:
          (json['random_contents'] as List)
              .map((e) => e is ManitoContent ? e : ManitoContent.fromJson(e))
              .toList(),
      contentType: missionsData['content_type'] as String,
      deadline: DateTime.parse(missionsData['deadline'] as String),
    );
  }

  ManitoPropose copyWith({
    String? id,
    String? creatorId,
    DateTime? acceptDeadline,
    String? missionId,
    List<ManitoContent>? randomContents,
    String? contentType,
    DateTime? deadline,
  }) {
    return ManitoPropose(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      acceptDeadline: acceptDeadline ?? this.acceptDeadline,
      missionId: missionId ?? this.missionId,
      randomContents: randomContents ?? this.randomContents,
      contentType: contentType ?? this.contentType,
      deadline: deadline ?? this.deadline,
    );
  }
}

// 사용안하고 있음
class ManitoProposeDetail {
  final String missionId;
  final List<ManitoContent> randomContents;
  final String contentType;
  final DateTime deadline;

  const ManitoProposeDetail({
    required this.missionId,
    required this.randomContents,
    required this.contentType,
    required this.deadline,
  });

  factory ManitoProposeDetail.fromJson(Map<String, dynamic> json) {
    final missions = json['missions'];

    return ManitoProposeDetail(
      missionId: json['mission_id'] as String,
      randomContents:
          (json['random_contents'] as List)
              .map((e) => e is ManitoContent ? e : ManitoContent.fromJson(e))
              .toList(),
      contentType: missions['content_type'] as String,
      deadline: DateTime.parse(missions['deadline']),
    );
  }
}

class ManitoAccept {
  final String id;
  final FriendProfile creatorProfile;
  final String content;
  final String status;
  final DateTime deadline;
  final String contentType;

  const ManitoAccept({
    required this.id,
    required this.creatorProfile,
    required this.content,
    required this.status,
    required this.deadline,
    required this.contentType,
  });

  factory ManitoAccept.fromJson(
    Map<String, dynamic> json,
    FriendProfile creatorProfile,
  ) {
    return ManitoAccept(
      id: json['id'] as String,
      creatorProfile: creatorProfile,
      content: json['content'] as String,
      status: json['status'] as String,
      deadline: DateTime.parse(json['deadline'] as String),
      contentType: json['content_type'] as String,
    );
  }
}

class ManitoGuess {
  final String id;
  final FriendProfile creatorProfile;

  const ManitoGuess({required this.id, required this.creatorProfile});

  factory ManitoGuess.fromJson(
    Map<String, dynamic> json,
    FriendProfile creatorProfile,
  ) {
    return ManitoGuess(
      id: json['id'] as String,
      creatorProfile: creatorProfile,
    );
  }
}

class ManitoContent {
  final String id;
  final String content;

  ManitoContent({required this.id, required this.content});

  factory ManitoContent.fromJson(Map<String, dynamic> json) {
    return ManitoContent(
      id: json['id'] as String,
      content: json['content'] as String,
    );
  }
}

class ManitoPost {
  final String? description;
  final List<String>? imageUrlList;

  const ManitoPost({this.description, this.imageUrlList});

  factory ManitoPost.fromJson(Map<String, dynamic> json) {
    return ManitoPost(
      description: json['description'] as String?,
      imageUrlList:
          json['image_url_list'] != null
              ? List<String>.from(json['image_url_list'] as List)
              : null,
    );
  }

  ManitoPost copyWith({String? description, List<String>? imageUrlList}) {
    return ManitoPost(
      description: description ?? this.description,
      imageUrlList: imageUrlList ?? this.imageUrlList,
    );
  }
}

// ========== State ==========
class ManitoListState {
  final List<ManitoPropose> proposeList;
  final List<ManitoAccept> acceptList;
  final List<ManitoGuess> guessList;

  ManitoListState({
    this.proposeList = const [],
    this.acceptList = const [],
    this.guessList = const [],
  });

  bool get isEmpty =>
      proposeList.isEmpty && acceptList.isEmpty && guessList.isEmpty;

  ManitoListState copyWith({
    bool? isLoading,
    List<ManitoPropose>? proposeList,
    List<ManitoAccept>? acceptList,
    List<ManitoGuess>? guessList,
    String? error,
  }) {
    return ManitoListState(
      proposeList: proposeList ?? this.proposeList,
      acceptList: acceptList ?? this.acceptList,
      guessList: guessList ?? this.guessList,
    );
  }
}

class ManitoProposeState {
  final ManitoProposeDetail? propose;
  final bool isAccepting;

  ManitoProposeState({this.isAccepting = false, this.propose});

  ManitoProposeState copyWith({
    bool? isAccepting,
    ManitoProposeDetail? propose,
    String? error,
  }) {
    return ManitoProposeState(
      isAccepting: isAccepting ?? this.isAccepting,
      propose: propose ?? this.propose,
    );
  }
}

class ManitoPostState {
  final ManitoAccept manitoAccept;
  final ManitoPost? post;
  final String description;
  final List<String> existingImageUrls;
  final List<AssetEntity> selectedImages;

  // 로딩 상태 유지
  final ManitoPostStatus status;

  const ManitoPostState({
    required this.manitoAccept,
    required this.status,
    this.post,
    this.description = '',
    this.existingImageUrls = const [],
    this.selectedImages = const [],
  });

  ManitoPostState copyWith({
    ManitoAccept? manitoAccept,
    ManitoPost? post,
    ManitoPostStatus? status,
    String? description,
    List<String>? existingImageUrls,
    List<AssetEntity>? selectedImages,
  }) {
    return ManitoPostState(
      manitoAccept: manitoAccept ?? this.manitoAccept,
      post: post ?? this.post,
      status: status ?? this.status,
      description: description ?? this.description,
      existingImageUrls: existingImageUrls ?? this.existingImageUrls,
      selectedImages: selectedImages ?? this.selectedImages,
    );
  }
}

enum ManitoPostStatus {
  editing, // 편집 중 (저장되지 않음)
  saving, // 저장 중
  saved, // 저장 완료
  posting, // 전송 중
  posted, // 전송 완료
}
