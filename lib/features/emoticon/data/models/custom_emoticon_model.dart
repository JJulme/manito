import 'package:hive_flutter/hive_flutter.dart';

/// 사용자 커스텀 사진 이모티콘 데이터 모델
class CustomEmoticonModel extends HiveObject {
  /// 고유 ID (timestamp 기반)
  final String id;

  /// 소유자 유저 ID (계정별 격리)
  final String userId;

  /// 검색용 태그 키워드 리스트 (예: ["ㅋㅋ", "웃김", "대박"])
  List<String> tags;

  /// 앱 Documents 디렉터리 내 저장된 이미지 경로
  final String localImagePath;

  /// 저장된 이미지 파일 크기 (bytes)
  final int fileSizeBytes;

  /// 등록 일시
  final DateTime createdAt;

  CustomEmoticonModel({
    required this.id,
    required this.userId,
    required this.tags,
    required this.localImagePath,
    required this.fileSizeBytes,
    required this.createdAt,
  });

  /// tags를 소문자 트림 처리한 검색용 리스트 반환
  List<String> get normalizedTags =>
      tags.map((t) => t.trim().toLowerCase()).where((t) => t.isNotEmpty).toList();

  /// 특정 키워드와 매칭되는지 확인
  bool matchesKeyword(String keyword) {
    final normalized = keyword.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return normalizedTags.any((tag) => tag == normalized);
  }

  CustomEmoticonModel copyWith({
    String? id,
    String? userId,
    List<String>? tags,
    String? localImagePath,
    int? fileSizeBytes,
    DateTime? createdAt,
  }) {
    return CustomEmoticonModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tags: tags ?? List<String>.from(this.tags),
      localImagePath: localImagePath ?? this.localImagePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Hive TypeAdapter (수동 작성 - build_runner 불필요)
class CustomEmoticonModelAdapter extends TypeAdapter<CustomEmoticonModel> {
  @override
  final int typeId = 1;

  @override
  CustomEmoticonModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomEmoticonModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      tags: (fields[2] as List).cast<String>(),
      localImagePath: fields[3] as String,
      fileSizeBytes: fields[4] as int,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CustomEmoticonModel obj) {
    writer
      ..writeByte(6) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.tags)
      ..writeByte(3)
      ..write(obj.localImagePath)
      ..writeByte(4)
      ..write(obj.fileSizeBytes)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomEmoticonModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
