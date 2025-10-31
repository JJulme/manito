import 'package:flutter/material.dart';
import 'package:manito/features/badge/badge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BadgeService {
  final SupabaseClient _supabase;
  BadgeService(this._supabase);

  /// 뱃지 목록 가져오기
  Future<List<BadgeModel>> fetchBadges() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];
      final data = await _supabase
          .from('badges')
          .select('type, type_id, count')
          .eq('user_id', userId);

      return (data as List).map((item) => BadgeModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('BadgeService.fetchBadges Error: $e');
      rethrow;
    }
  }

  /// 특정 뱃지 초기화
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
      debugPrint('resetBadgeCount Error: $e');
      rethrow;
    }
  }
}
