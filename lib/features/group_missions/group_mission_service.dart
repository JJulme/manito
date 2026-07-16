import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupMissionService {
  final SupabaseClient _supabase;
  GroupMissionService(this._supabase);

  // 내가 추측할 그룹 미션 가져오기
  Future<void> fetchMyGroupMission() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('group_missions')
          .select('id, deadline')
          .eq('target_id', userId);
      print(data);
    } catch (e) {
      debugPrint('GroupMissionService.fetchMyGroupMission Error: $e');
      rethrow;
    }
  }
}

class GroupMissionCreateService {
  final SupabaseClient _supabase;
  GroupMissionCreateService(this._supabase);

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
      debugPrint('MissionGroupCreateService.createGroupMissionRoom Error: $e');
      rethrow;
    }
  }
}
