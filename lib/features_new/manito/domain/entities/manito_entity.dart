import 'package:manito/features_new/friends/domain/entities/friend_entity.dart';
import 'package:photo_manager/photo_manager.dart';

class ManitoProposeEntity {
  final String id;
  final String creatorId;
  final DateTime acceptDeadline;

  final String? missionId;
  final List<ManitoContentEntity>? randomContents;
  final String? contentType;
  final DateTime? deadline;

  const ManitoProposeEntity({
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

  factory ManitoProposeEntity.fromJson(Map<String, dynamic> json) {
    return ManitoProposeEntity(
      id: json['id'] as String,
      creatorId: json['missions']['creator_id'] as String,
      acceptDeadline: DateTime.parse(
        json['missions']['accept_deadline'] as String,
      ),
    );
  }

  factory ManitoProposeEntity.fromDetailJson(Map<String, dynamic> json) {
    final missionsData = json['missions'] as Map<String, dynamic>;
    return ManitoProposeEntity(
      id: json['id'] as String,
      missionId: json['mission_id'] as String,
      creatorId: missionsData['creator_id'] as String,
      acceptDeadline: DateTime.parse(missionsData['accept_deadline'] as String),
      randomContents:
          (json['random_contents'] as List)
              .map((e) => e is ManitoContentEntity ? e : ManitoContentEntity.fromJson(e))
              .toList(),
      contentType: missionsData['content_type'] as String,
      deadline: DateTime.parse(missionsData['deadline'] as String),
    );
  }

  ManitoProposeEntity copyWith({
    String? id,
    String? creatorId,
    DateTime? acceptDeadline,
    String? missionId,
    List<ManitoContentEntity>? randomContents,
    String? contentType,
    DateTime? deadline,
  }) {
    return ManitoProposeEntity(
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

class ManitoAcceptEntity {
  final String id;
  final FriendProfileEntity creatorProfile;
  final String content;
  final String status;
  final DateTime deadline;
  final String contentType;

  const ManitoAcceptEntity({
    required this.id,
    required this.creatorProfile,
    required this.content,
    required this.status,
    required this.deadline,
    required this.contentType,
  });

  factory ManitoAcceptEntity.fromJson(
    Map<String, dynamic> json,
    FriendProfileEntity creatorProfile,
  ) {
    return ManitoAcceptEntity(
      id: json['id'] as String,
      creatorProfile: creatorProfile,
      content: json['content'] as String,
      status: json['status'] as String,
      deadline: DateTime.parse(json['deadline'] as String),
      contentType: json['content_type'] as String,
    );
  }
}

class ManitoGuessEntity {
  final String id;
  final FriendProfileEntity creatorProfile;

  const ManitoGuessEntity({required this.id, required this.creatorProfile});

  factory ManitoGuessEntity.fromJson(
    Map<String, dynamic> json,
    FriendProfileEntity creatorProfile,
  ) {
    return ManitoGuessEntity(
      id: json['id'] as String,
      creatorProfile: creatorProfile,
    );
  }
}

class ManitoContentEntity {
  final String id;
  final String content;

  ManitoContentEntity({required this.id, required this.content});

  factory ManitoContentEntity.fromJson(Map<String, dynamic> json) {
    return ManitoContentEntity(
      id: json['id'] as String,
      content: json['content'] as String,
    );
  }
}

class ManitoPostEntity {
  final String? description;
  final List<String>? imageUrlList;

  const ManitoPostEntity({this.description, this.imageUrlList});

  factory ManitoPostEntity.fromJson(Map<String, dynamic> json) {
    return ManitoPostEntity(
      description: json['description'] as String?,
      imageUrlList:
          json['image_url_list'] != null
              ? List<String>.from(json['image_url_list'] as List)
              : null,
    );
  }

  ManitoPostEntity copyWith({String? description, List<String>? imageUrlList}) {
    return ManitoPostEntity(
      description: description ?? this.description,
      imageUrlList: imageUrlList ?? this.imageUrlList,
    );
  }
}

enum ManitoPostStatus {
  editing,
  saving,
  saved,
  posting,
  posted,
}

class ManitoListState {
  final List<ManitoProposeEntity> proposeList;
  final List<ManitoAcceptEntity> acceptList;
  final List<ManitoGuessEntity> guessList;

  ManitoListState({
    this.proposeList = const [],
    this.acceptList = const [],
    this.guessList = const [],
  });

  bool get isEmpty =>
      proposeList.isEmpty && acceptList.isEmpty && guessList.isEmpty;

  ManitoListState copyWith({
    bool? isLoading,
    List<ManitoProposeEntity>? proposeList,
    List<ManitoAcceptEntity>? acceptList,
    List<ManitoGuessEntity>? guessList,
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
  final ManitoProposeEntity? propose;
  final bool isAccepting;

  ManitoProposeState({this.isAccepting = false, this.propose});

  ManitoProposeState copyWith({
    bool? isAccepting,
    ManitoProposeEntity? propose,
    String? error,
  }) {
    return ManitoProposeState(
      isAccepting: isAccepting ?? this.isAccepting,
      propose: propose ?? this.propose,
    );
  }
}

class ManitoPostState {
  final ManitoAcceptEntity manitoAccept;
  final ManitoPostEntity? post;
  final String description;
  final List<String> existingImageUrls;
  final List<AssetEntity> selectedImages;
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
    ManitoAcceptEntity? manitoAccept,
    ManitoPostEntity? post,
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
