import 'package:manito/core/badge/domain/entities/badge_entity.dart';

abstract class BadgeRepository {
  Future<List<BadgeEntity>> fetchBadges();
  Future<void> resetBadgeCount(String type, {String? typeId});
}
