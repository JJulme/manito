class MissionModel {
  final int missionId;
  final String category;
  final String contentKo;
  final String contentEn;
  final bool isActive;
  final DateTime createdAt;

  const MissionModel({
    required this.missionId,
    required this.category,
    required this.contentKo,
    required this.contentEn,
    required this.isActive,
    required this.createdAt,
  });

  String getContent(String languageCode) {
    if (languageCode.startsWith('en')) {
      return contentEn;
    }
    return contentKo;
  }

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      missionId: json['mission_id'] as int,
      category: json['category'] as String,
      contentKo: json['content_ko'] as String,
      contentEn: json['content_en'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mission_id': missionId,
      'category': category,
      'content_ko': contentKo,
      'content_en': contentEn,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
