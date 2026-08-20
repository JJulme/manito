import 'package:flutter/material.dart';
import 'package:manito/features_new/group_missions/domain/repositories/group_missions_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupMissionsRepositoryImpl implements GroupMissionsRepository {
  final SupabaseClient _supabase;

  GroupMissionsRepositoryImpl(this._supabase);

  @override
  Future<void> fetchMyGroupMission() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('group_missions')
          .select('id, deadline')
          .eq('target_id', userId);
      debugPrint('GroupMissionsRepositoryImpl: $data');
    } catch (e) {
      debugPrint('GroupMissionsRepositoryImpl.fetchMyGroupMission Error: $e');
      rethrow;
    }
  }

  @override
  Future<String> createGroupRoom({
    required String title,
    required String contentType,
    required String limitTime,
  }) async {
    try {
      final creatorId = _supabase.auth.currentUser!.id;
      final data =
          await _supabase
              .from('group_rooms')
              .insert({
                "creator_id": creatorId,
                "title": title,
                "content_type": contentType,
                "limit_time": limitTime,
              })
              .select('id')
              .single();
      return data['id'];
    } catch (e) {
      debugPrint('GroupMissionsRepositoryImpl.createGroupRoom Error: $e');
      rethrow;
    }
  }
}
