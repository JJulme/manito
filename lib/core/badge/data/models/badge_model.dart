import 'package:manito/core/badge/domain/entities/badge_entity.dart';

class BadgeModel extends BadgeEntity {
  const BadgeModel({
    required super.type,
    required super.typeId,
    required super.count,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      type: json['type'] as String,
      typeId: json['type_id'] as String,
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'type_id': typeId,
      'count': count,
    };
  }
}
