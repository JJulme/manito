import 'package:flutter/material.dart';
import 'package:manito/features_new/missions/domain/repositories/missions_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MissionsRepositoryImpl implements MissionsRepository {
  final SupabaseClient _supabase;
  MissionsRepositoryImpl(this._supabase);

  /// 내가 생성한 미션 데이터 가져오기
  @override
  Future<List<Map<String, dynamic>>> fetchMyMissionsData() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final List<dynamic> missionsData = await _supabase
          .from('missions')
          .select(
            'id, friend_ids, status, content_type, deadline, accept_deadline, created_at',
          )
          .eq('creator_id', userId)
          .isFilter('guess', null);
      return missionsData.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('MissionsRepositoryImpl.fetchMyMissionsData Error: $e');
      rethrow;
    }
  }

  /// 싱글 미션 생성
  @override
  Future<void> createSingleMission({
    required List<String> friendIds,
    required String contentType,
    required DateTime acceptDeadline,
    required DateTime deadline,
  }) async {
    try {
      final creatorId = _supabase.auth.currentUser!.id;
      await _supabase.from('missions').insert({
        "creator_id": creatorId,
        "friend_ids": friendIds,
        "accept_deadline": acceptDeadline.toIso8601String(),
        "deadline": deadline.toIso8601String(),
        "content_type": contentType,
      });
    } catch (e) {
      debugPrint('MissionsRepositoryImpl.createSingleMission Error: $e');
      rethrow;
    }
  }

  /// 그룹 미션 생성
  @override
  Future<void> createGroupMission({
    required List<String> friendIds,
    required String contentType,
    required DateTime deadline,
  }) async {
    try {
      final creatorId = _supabase.auth.currentUser!.id;
      final allIds = [...friendIds, creatorId];
      await _supabase.rpc(
        'create_group_room',
        params: {
          "p_user_ids": allIds,
          "p_content_type": contentType,
          "p_deadline": deadline.toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('MissionsRepositoryImpl.createGroupMission Error: $e');
      rethrow;
    }
  }

  /// 그룹 방 생성
  @override
  Future<String> createGroupRoom({
    required String title,
    required String contentType,
    required String limitTime,
  }) async {
    try {
      final creatorId = _supabase.auth.currentUser!.id;
      final data = await _supabase
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
      debugPrint('MissionsRepositoryImpl.createGroupRoom Error: $e');
      rethrow;
    }
  }

  /// 미션 추측 업데이트
  @override
  Future<void> updateMissionGuess(String missionId, String text) async {
    try {
      await _supabase.rpc(
        'mission_complete',
        params: {'p_mission_id': missionId, 'p_guess': text},
      );
    } catch (e) {
      debugPrint('MissionsRepositoryImpl.updateMissionGuess Error: $e');
      rethrow;
    }
  }
}
