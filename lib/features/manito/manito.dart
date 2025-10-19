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
  final bool isLoading;
  final List<ManitoPropose> proposeList;
  final List<ManitoAccept> acceptList;
  final List<ManitoGuess> guessList;
  final String? error;

  ManitoListState({
    this.isLoading = false,
    this.proposeList = const [],
    this.acceptList = const [],
    this.guessList = const [],
    this.error,
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
      isLoading: isLoading ?? this.isLoading,
      proposeList: proposeList ?? this.proposeList,
      acceptList: acceptList ?? this.acceptList,
      guessList: guessList ?? this.guessList,
      error: error ?? this.error,
    );
  }
}

class ManitoProposeState {
  final bool isLoading;
  final ManitoPropose? propose;
  final String? error;

  ManitoProposeState({this.isLoading = false, this.propose, this.error});

  bool get pageLoading => isLoading || !propose!.isDetailLoaded;

  const ManitoProposeState.initial(ManitoPropose originalPropose)
    : isLoading = false,
      propose = originalPropose,
      error = null;

  ManitoProposeState copyWith({
    bool? isLoading,
    ManitoPropose? propose,
    String? error,
  }) {
    return ManitoProposeState(
      isLoading: isLoading ?? this.isLoading,
      propose: propose ?? this.propose,
      error: error ?? this.error,
    );
  }
}

class ManitoPostState {
  final ManitoAccept manitoAccept;
  final ManitoPost? post;
  final List<AssetEntity> selectedImages;
  final List<String> existingImageUrls;
  final ManitoPostStatus status;
  final String description;
  final String? error;

  const ManitoPostState({
    required this.manitoAccept,
    this.post,
    this.selectedImages = const [],
    this.existingImageUrls = const [],
    this.status = ManitoPostStatus.initial,
    this.description = '',
    this.error,
  });

  bool get isLoading => status == ManitoPostStatus.loading;
  bool get isSaving => status == ManitoPostStatus.saving;
  bool get isPosting => status == ManitoPostStatus.posting;
  bool get hasError => status == ManitoPostStatus.error;
  bool get isEditing => status == ManitoPostStatus.editing;

  int get totalImageCount => selectedImages.length + existingImageUrls.length;
  bool get hasContent => description.isNotEmpty;

  // 저장 가능 여부: 편집 중이고, 저장/전송 중이 아닐 때
  bool get canSave => isEditing && hasContent;

  // 전송 가능 여부: 저장 완료 상태이고, 내용이 있을 때
  bool get canPost => status == ManitoPostStatus.saved && hasContent;

  // 편집 가능 여부: 전송 중이거나 완료 상태가 아닐 때
  bool get canEdit =>
      status != ManitoPostStatus.posting && status != ManitoPostStatus.posted;

  ManitoPostState setLoading() {
    return copyWith(status: ManitoPostStatus.loading, error: null);
  }

  ManitoPostState setLoaded(ManitoPost post) {
    return copyWith(
      post: post,
      description: post.description ?? '',
      existingImageUrls: post.imageUrlList ?? [],
      status: ManitoPostStatus.saved, // 기존 데이터는 저장된 상태
      error: null,
    );
  }

  // 앨범에서 선택했던 사진 삭제
  ManitoPostState removeSelectedImage(int index) {
    final newList = List<AssetEntity>.from(selectedImages)..removeAt(index);
    return copyWith(selectedImages: newList, status: ManitoPostStatus.editing);
  }

  // 서버에 저장했던 사진 삭제
  ManitoPostState removeExistingImage(int index) {
    final newList = List<String>.from(existingImageUrls)..removeAt(index);
    return copyWith(
      existingImageUrls: newList,
      status: ManitoPostStatus.editing,
    );
  }

  ManitoPostState addSelectedImage(List<AssetEntity> images) {
    return copyWith(selectedImages: images, status: ManitoPostStatus.editing);
  }

  // Content modifications
  ManitoPostState updateDescription(String desc) {
    return copyWith(description: desc, status: ManitoPostStatus.editing);
  }

  ManitoPostState setSaving() {
    return copyWith(status: ManitoPostStatus.saving, error: null);
  }

  ManitoPostState setSaved(List<String> uploadedImageUrls) {
    return copyWith(
      status: ManitoPostStatus.saved,
      selectedImages: [],
      existingImageUrls: uploadedImageUrls,
      error: null,
    );
  }

  ManitoPostState setPosting() {
    return copyWith(status: ManitoPostStatus.posting, error: null);
  }

  ManitoPostState setPosted() {
    return copyWith(status: ManitoPostStatus.posted, error: null);
  }

  ManitoPostState setError(String errorMessage) {
    return copyWith(status: ManitoPostStatus.error, error: errorMessage);
  }

  ManitoPostState copyWith({
    ManitoAccept? manitoAccept,
    ManitoPost? post,
    List<AssetEntity>? selectedImages,
    List<String>? existingImageUrls,
    ManitoPostStatus? status,
    String? description,
    String? error,
  }) {
    return ManitoPostState(
      manitoAccept: manitoAccept ?? this.manitoAccept,
      post: post ?? this.post,
      selectedImages: selectedImages ?? this.selectedImages,
      existingImageUrls: existingImageUrls ?? this.existingImageUrls,
      status: status ?? this.status,
      description: description ?? this.description,
      error: error ?? this.error,
    );
  }
}

enum ManitoPostStatus {
  initial, // 초기 상태
  loading, // 데이터 로딩 중
  loaded, // 데이터 로드 완료
  editing, // 편집 중 (저장되지 않음)
  saving, // 저장 중
  saved, // 저장 완료
  posting, // 전송 중
  posted, // 전송 완료
  error, // 에러
}
