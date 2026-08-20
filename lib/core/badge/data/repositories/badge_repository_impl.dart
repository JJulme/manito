import 'package:flutter/material.dart';
import 'package:manito/core/badge/data/models/badge_model.dart';
import 'package:manito/core/badge/domain/entities/badge_entity.dart';
import 'package:manito/core/badge/domain/repositories/badge_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BadgeRepositoryImpl implements BadgeRepository {
  final SupabaseClient _supabase;
  BadgeRepositoryImpl(this._supabase);

  @override
  Future<List<BadgeEntity>> fetchBadges() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];
      final data = await _supabase
          .from('badges')
          .select('type, type_id, count')
          .eq('user_id', userId);

      return (data as List).map((item) => BadgeModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('BadgeRepositoryImpl.fetchBadges Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> resetBadgeCount(String type, {String? typeId}) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      var query = _supabase
          .from('badges')
          .update({'count': 0})
          .eq('user_id', userId)
          .eq('type', type);

      if (typeId != null) {
        query = query.eq('type_id', typeId);
      }
      await query;
    } catch (e) {
      debugPrint('BadgeRepositoryImpl.resetBadgeCount Error: $e');
      rethrow;
    }
  }
}
