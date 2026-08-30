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
      missionId: (json['mission_id'] as num?)?.toInt() ?? 0,
      category: json['category']?.toString() ?? '',
      contentKo: json['content_ko']?.toString() ?? '',
      contentEn: json['content_en']?.toString() ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
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
