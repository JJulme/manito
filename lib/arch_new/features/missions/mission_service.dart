import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MissionService {
  final SupabaseClient _supabase;
  MissionService(this._supabase);

  /// 내가 생성한 미션 데이터 가져오기
  Future<List<Map<String, dynamic>>> fetchMyMissionsData(String userId) async {
    try {
      final List<dynamic> missionsData = await _supabase
          .from('missions')
          .select(
            'id, friend_ids, status, content_type, deadline, accept_deadline, created_at',
          )
          .eq('creator_id', userId)
          .isFilter('guess', null);

      return missionsData.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('MissionService.fetchMyMissionsData Error: $e');
      rethrow;
    }
  }
}

class MissionCreateService {
  final SupabaseClient _supabase;
  MissionCreateService(this._supabase);

  /// 미션 생성
  Future<String> createMission({
    required String creatorId,
    required List<String> friendIds,
    required String contentType,
    required String deadlineType,
  }) async {
    try {
      final String result = await _supabase.rpc(
        'create_mission',
        params: {
          'creator_id': creatorId,
          'friend_ids': friendIds,
          'content_type': contentType,
          'deadline_type': deadlineType,
        },
      );

      return result;
    } catch (e) {
      debugPrint('MissionCreateService.createMission Error: $e');
      rethrow;
    }
  }
}

class MissionGuessService {
  final SupabaseClient _supabase;
  MissionGuessService(this._supabase);

  /// 미션 추측 업데이트 - 수정 필요
  Future<void> updateMissionGuess(String missionId, String text) async {
    try {
      await _supabase.rpc(
        'mission_complete',
        params: {'p_mission_id': missionId, 'p_guess': text},
      );
    } catch (e) {
      debugPrint('MissionGuessService.updateMissionGuess Error: $e');
    }
  }
}
